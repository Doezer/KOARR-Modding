-- Quest Hider preview. Only journal display state and this mod's preferences change.
local G = _G
local existing = rawget(G, "QuestHider")
if existing and existing.enabled then existing.attach(); return existing end
local function log(s) print("[QuestHider] " .. s) end
local N = rawget(G, "QuestHiderNative")
if type(N) ~= "table" and type(package) == "table" and type(package.loadlib) == "function" then
    local loader = package.loadlib("mods/quest_hider_native.dll", "luaopen_QuestHiderNative")
    if loader then pcall(loader) end
    N = rawget(G, "QuestHiderNative")
end
if type(N) ~= "table" or type(N.initialize) ~= "function" then
    log("Native helper unavailable. Install quest_hider_native.dll and restart; no journal hooks installed.")
    return false
end
if not N.initialize("QuestHider") then
    log("Native compatibility check failed; no journal hooks installed. Check native startup log.")
    return false
end
local config_chunk, config_error = loadfile("mods/QuestHider/config.lua")
if not config_chunk then log("Cannot load config: " .. tostring(config_error)); return false end
local config = config_chunk()
local function valid_key(k) return type(k) == "number" and k >= 1 and k <= 255 and k == math.floor(k) end
if type(config) ~= "table" or not valid_key(config.toggle_key) or not valid_key(config.hidden_list_key)
    or config.toggle_key == config.hidden_list_key or type(config.profile) ~= "string" then
    log("Invalid config; no journal hooks installed."); return false
end
local S = {enabled=true, hidden_view=false, profile_ready=false, hooks={}, version="0.1.0-preview"}
G.QuestHider = S
local function pack(...) return {n=select("#", ...), ...} end
local function unpacked(t) return unpack(t, 1, t.n) end
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
local profile_warning = false
function S.sync_profile()
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
end
function S.toggle_selected()
    local qw=rawget(G,"quests_win")
    if type(qw) ~= "table" or type(qw.get_selected_quest) ~= "function" or not S.sync_profile() then return false end
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
    if not S.sync_profile() then return false end
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
            S.hidden_view=false;S.sync_profile()
            N.poll(tostring(config.toggle_key));N.poll(tostring(config.hidden_list_key))
            log("F6: hide/restore selected quest. F7: normal/hidden list.")
        end
        local result=pack(original(event,...))
        if event=="START_CLOSE" then S.hidden_view=false end
        return unpacked(result)
    end end)
    wrap(qw,"on_update_event",function(original) return function(dt,window,...)
        local result=pack(original(dt,window,...))
        local W=rawget(G,"WINDOW")
        if S.enabled and qw.m_inited and type(W)=="table" and type(W.is_visible)=="function"
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
    S.enabled=false;S.profile_ready=false;N.suspend()
    for i=#S.hooks,1,-1 do
        local h=S.hooks[i]
        if h.module[h.name]==h.replacement then h.module[h.name]=h.original end
    end
    return true
end
S.attach()
log("Preview loaded. Open the journal: F6 hides/restores, F7 opens hidden quests.")
return S
