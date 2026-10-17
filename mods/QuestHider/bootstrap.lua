-- Catch Lua startup errors before they escape the framework's unprotected call.
local function bootstrap()
-- Quest Hider preview. Only journal display state and this mod's preferences change.
local G = _G
local existing = rawget(G, "QuestHider")
if existing and existing.enabled then existing.attach(); return existing end
local function log(s) print("[QuestHider] " .. s) end
local N = rawget(G, "QuestHiderNative")
-- The framework loads config.lua first. Do not nest the game's asset loader
-- inside a framework require callback or initialize native rendering at startup.
local config = rawget(G, "QuestHiderConfig")
log("Startup: configuration received; native initialization deferred until journal SHOW.")
if type(N) ~= "table" then
    log("Native helper unavailable; no journal hooks installed.")
    return false
end
for _,name in ipairs({"initialize","profile","suspend","is_hidden","set_hidden","poll"}) do
    if type(N[name]) ~= "function" then
        log("Native API incomplete (" .. name .. "); no journal hooks installed.")
        return false
    end
end
local function valid_key(k) return type(k) == "number" and k >= 1 and k <= 255 and k == math.floor(k) end
if type(config) ~= "table" or not valid_key(config.toggle_key) or not valid_key(config.hidden_list_key)
    or config.toggle_key == config.hidden_list_key or type(config.profile) ~= "string" then
    log("Invalid config; no journal hooks installed."); return false
end
local S = {enabled=true, hidden_view=false, profile_ready=false, hooks={}, version="0.1.1-preview", native_ready=false, native_attempted=false}
G.QuestHider = S
local function pack(...) return {n=select("#", ...), ...} end
local function unpacked(t) return unpack(t, 1, t.n) end
-- Use the journal's existing reminder label, discovered from its own setter call.
-- No UI resource IDs or new window layouts are needed.
local reminder, reminder_scope
local function key_name(key)
    if key >= 112 and key <= 135 then return "F" .. tostring(key - 111) end
    if (key >= 48 and key <= 57) or (key >= 65 and key <= 90) then return string.char(key) end
    local names = {[8]="Backspace",[9]="Tab",[13]="Enter",[16]="Shift",[17]="Ctrl",
        [18]="Alt",[19]="Pause",[20]="Caps Lock",[27]="Esc",[32]="Space",
        [33]="Page Up",[34]="Page Down",[35]="End",[36]="Home",[37]="Left",
        [38]="Up",[39]="Right",[40]="Down",[45]="Insert",[46]="Delete"}
    return names[key] or ("VK " .. tostring(key))
end
local function hint_text()
    return key_name(config.toggle_key) .. (S.hidden_view and ": Restore" or ": Hide")
        .. " | " .. key_name(config.hidden_list_key)
        .. (S.hidden_view and ": Show Normal" or ": Show Hidden")
end
local function update_hint()
    if S.enabled and reminder then reminder.write(reminder.label, hint_text()) end
end
local function restore_hint()
    if reminder then
        local old=reminder;reminder=nil
        old.setter(unpacked(old.args))
    end
end
local function capture_reminder(original, ...)
    local W=rawget(G,"WINDOW")
    if type(W)~="table" or type(W.set_label_text)~="function" then return original(...) end
    local changed={}
    local write=W.set_label_text
    local captured
    for _,name in ipairs({"set_label_text", "set_label_text_formatted",
        "set_label_text_no_loc_fix_up", "set_label_text_with_built_string"}) do
        local setter=W[name]
        if type(setter)=="function" then
            local replacement=function(...)
                local args=pack(...)
                local result=pack(setter(...))
                if args[1] then captured={label=args[1],write=write,setter=setter,args=args} end
                return unpacked(result)
            end
            changed[#changed+1]={name=name,setter=setter,replacement=replacement}
            W[name]=replacement
        end
    end
    local result=pack(pcall(original,...))
    for _,change in ipairs(changed) do
        if W[change.name]==change.replacement then W[change.name]=change.setter end
    end
    if not result[1] then error(result[2],0) end
    if captured then reminder=captured;update_hint()
    else log("Journal reminder label unavailable; key hints remain in the log.") end
    return unpack(result,2,result.n)
end
local function quest_key(entry)
    if type(entry) ~= "table" or type(entry.collapsed) == "boolean" or entry.id == nil then return nil end
    local api = rawget(G, "QUEST")
    if type(api) ~= "table" or type(api.get_quest_key_as_int) ~= "function" then return nil end
    local key = api.get_quest_key_as_int(entry.id)
    if type(key) ~= "number" or key < 1 or key > 268435455 or key ~= math.floor(key) then return nil end
    return string.format("%.0f", key)
end
local function hidden(entry)
    local key = quest_key(entry)
    return S.profile_ready and key ~= nil and not not N.is_hidden(key)
end
local function entries(qw)
    if type(qw.m_quest_data) == "table" and type(qw.m_quest_data.quests) == "table" then
        return qw.m_quest_data.quests
    end
    return {}
end
local function accepted(entry)
    if type(entry) ~= "table" then return false end
    if type(entry.collapsed) == "boolean" then return true end
    if not S.profile_ready then return true end
    return hidden(entry) == S.hidden_view
end
function S.ensure_native()
    if S.native_ready then return true end
    if S.native_attempted then return false end
    S.native_attempted=true
    log("Native initialize: enter (journal opened).")
    local ok,result=pcall(N.initialize,"QuestHider")
    log("Native initialize: returned " .. (ok and (result and "success" or "disabled") or "Lua error") .. ".")
    S.native_ready=ok and not not result
    if not S.native_ready then log("Quest filtering disabled; original journal remains available.") end
    return S.native_ready
end
local profile_warning = false
function S.sync_profile()
    if not S.native_ready then S.profile_ready=false;return false end
    local name = config.profile
    if name == "" then
        local player = rawget(G, "PLAYER")
        if type(player) == "table" and type(player.get_player_name) == "function" then
            name = player.get_player_name()
        end
    end
    if type(name) ~= "string" or name == "" or not N.profile(name) then
        S.profile_ready=false; N.suspend()
        if not profile_warning then log("Waiting for a player profile; quest filtering disabled."); profile_warning=true end
        return false
    end
    profile_warning=false;S.profile_ready=true;return true
end
local function wrap(module, name, make)
    if type(module) ~= "table" or type(module[name]) ~= "function" then return false end
    for _, h in ipairs(S.hooks) do if h.module == module and h.name == name then return true end end
    local original=module[name]
    local replacement=make(original)
    module[name]=replacement
    S.hooks[#S.hooks+1]={module=module,name=name,original=original,replacement=replacement}
    return true
end
local function choose(qw, wanted)
    local rows=entries(qw)
    if rows[wanted] and (type(rows[wanted].collapsed) == "boolean" or rows[wanted].visible)
        and accepted(rows[wanted]) then return wanted end
    for i,row in ipairs(rows) do
        if type(row.collapsed) ~= "boolean" and row.visible and accepted(row) then return i end
    end
    for i,row in ipairs(rows) do if type(row.collapsed) == "boolean" then return i end end
    return wanted
end
local function refresh(qw)
    if type(qw.rebuild_quest_list) == "function" then qw.rebuild_quest_list() end
    if type(qw.update_stage_information) == "function" then qw.update_stage_information() end
    if type(qw.update_information_window) == "function" then qw.update_information_window() end
    update_hint()
end
function S.toggle_selected()
    local qw=rawget(G,"quests_win")
    if type(qw) ~= "table" or type(qw.get_selected_quest) ~= "function" or not S.native_ready or not S.sync_profile() then return false end
    local entry=qw.get_selected_quest()
    local key=quest_key(entry)
    if not key then log("Select a quest row first."); return false end
    local was_hidden=hidden(entry)
    if entry.finished and not was_hidden then log("Only ongoing quests can be hidden.");return false end
    local action=was_hidden and "show" or "hide"
    if not N.set_hidden(key,action) then log("Could not save preference; quest left unchanged.");return false end
    refresh(qw)
    log(was_hidden and "Quest restored." or "Quest hidden. F7 opens the hidden list.")
    return true
end
function S.toggle_view()
    if not S.native_ready or not S.sync_profile() then return false end
    local qw=rawget(G,"quests_win")
    if type(qw) ~= "table" then return false end
    S.hidden_view=not S.hidden_view
    refresh(qw)
    local count=0
    for _,entry in ipairs(entries(qw)) do if hidden(entry) then count=count+1 end end
    log((S.hidden_view and "Hidden quests" or "Normal journal") .. " (" .. count .. " hidden). F6 hides/restores; F7 switches lists.")
    return true
end
local function attach_journal(qw)
    -- Every integration point below occurs in the privately supplied journal export.
    if type(qw) ~= "table" or type(qw.rebuild_quest_list) ~= "function"
        or type(qw.get_selected_quest) ~= "function" then return end
    wrap(rawget(G,"ledger_win"),"set_reminder",function(original) return function(...)
        if S.enabled and reminder_scope then return capture_reminder(original,...) end
        -- A different ledger page now owns the shared reminder label.
        reminder=nil
        return original(...)
    end end)
    wrap(qw,"update_rose",function(original) return function(...)
        local result=pack(original(...))
        update_hint()
        return unpacked(result)
    end end)
    wrap(qw,"rebuild_quest_list",function(original) return function(...)
        if not S.enabled then return original(...) end
        local saved={}
        for _,entry in ipairs(entries(qw)) do
            if type(entry) == "table" and type(entry.collapsed) ~= "boolean" then
                saved[#saved+1]={entry=entry,visible=entry.visible}
                entry.visible=entry.visible and accepted(entry)
            end
        end
        local result=pack(pcall(original,...))
        for _,state in ipairs(saved) do state.entry.visible=state.visible end
        if not result[1] then error(result[2],0) end
        return unpack(result,2,result.n)
    end end)
    wrap(qw,"get_starting_selected_quest_index",function(original) return function(...)
        local wanted=original(...)
        if not S.enabled then return wanted end
        return choose(qw,wanted)
    end end)
    wrap(qw,"set_selected_quest",function(original) return function(index,...)
        if S.enabled then index=choose(qw,index) end
        return original(index,...)
    end end)
    wrap(qw,"add_template",function(original) return function(index,...)
        local result=pack(original(index,...))
        local entry=entries(qw)[index]
        local W=rawget(G,"WINDOW")
        local Q=rawget(G,"QUEST")
        if S.enabled and S.hidden_view and result[1] and hidden(entry)
            and type(W)=="table" and type(W.find_static)=="function" and type(W.set_label_text)=="function"
            and type(Q)=="table" and type(Q.get_name)=="function" then
            local label=W.find_static(result[1],6511329,-1,true)
            local name=Q.get_name(entry.id)
            if label and type(name)=="string" then W.set_label_text(label,"[Hidden] "..name) end
        end
        return unpacked(result)
    end end)
    wrap(qw,"on_window_event",function(original) return function(event,...)
        if S.enabled and event=="SHOW" then
            S.hidden_view=false
            if S.ensure_native() then
                S.sync_profile()
                N.poll(tostring(config.toggle_key));N.poll(tostring(config.hidden_list_key))
            end
            log("F6: hide/restore selected quest. F7: normal/hidden list.")
        end
        if event=="START_CLOSE" then restore_hint();S.hidden_view=false end
        local previous_scope=reminder_scope
        reminder_scope=S.enabled and S.native_ready and event=="SHOW"
        local result=pack(pcall(original,event,...))
        reminder_scope=previous_scope
        if not result[1] then
            if event=="SHOW" then restore_hint() end
            error(result[2],0)
        end
        return unpack(result,2,result.n)
    end end)
    wrap(qw,"on_update_event",function(original) return function(dt,window,...)
        local result=pack(original(dt,window,...))
        local W=rawget(G,"WINDOW")
        if S.enabled and S.native_ready and qw.m_inited and type(W)=="table" and type(W.is_visible)=="function"
            and (window or qw.m_window) and W.is_visible(window or qw.m_window) then
            local toggle=N.poll(tostring(config.toggle_key))
            local view=N.poll(tostring(config.hidden_list_key))
            if toggle then S.toggle_selected() elseif view then S.toggle_view() end
        end
        return unpacked(result)
    end end)
end
function S.attach()
    attach_journal(rawget(G,"quests_win"))
    local M=rawget(G,"MAP")
    wrap(M,"set_map_window_region",function(original) return function(...)
        if S.enabled then S.sync_profile() end
        return original(...)
    end end)
    local mini=rawget(G,"minimap_win")
    local ticks=0
    wrap(mini,"on_update_event",function(original) return function(...)
        if S.enabled then ticks=ticks+1;if ticks==1 or ticks>=30 then ticks=1;S.sync_profile() end end
        return original(...)
    end end)
end
function S.detach()
    restore_hint()
    S.enabled=false;S.profile_ready=false
    if S.native_ready then N.suspend() end
    for i=#S.hooks,1,-1 do
        local h=S.hooks[i]
        if h.module[h.name]==h.replacement then h.module[h.name]=h.original end
    end
    return true
end
S.attach()
log("Lua adapter ready; native initialization awaits journal SHOW. F6 hides/restores, F7 switches lists.")
return S

end
local ok,result=pcall(bootstrap)
if not ok then
    local partial=rawget(_G,"QuestHider")
    if type(partial)=="table" and type(partial.detach)=="function" then pcall(partial.detach) end
    print("[QuestHider] Lua bootstrap failed; adapter disabled: "..tostring(result))
    return false
end
return result
