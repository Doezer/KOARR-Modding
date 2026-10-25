-- Inventory Plus technical spike: passive inspection only, never call unknown game APIs.
local G=_G
local old=rawget(G,"InventoryPlusProbe")
if type(old)=="table" and old.active then old.collect();return old end
local S={active=true,version="0.1.2",seen={},hooks={},bytes=0,events=0}
G.InventoryPlusProbe=S
local function log(text) print("[InventoryPlusProbe] "..text) end
local function pack(...) return {n=select("#",...),...} end
local function unpacked(t) return unpack(t,1,t.n) end
local function label(s)
    return type(s)=="string" and #s<=96 and string.match(s,"^[A-Za-z_][A-Za-z0-9_]*$")
end
local function keys(t,limit)
    local result={}
    local visited=0
    for k in next,t do
        visited=visited+1;if visited>limit then break end
        if label(k) then result[#result+1]=k end
    end
    table.sort(result);return result
end
local function scalar(v)
    local t=type(v)
    if t=="string" then
        -- Log only bounded escaped game/module data, never use an opaque __tostring.
        local text=string.gsub(string.sub(v,1,80),"[^ -~]",function(c)
            return string.format("\\x%02x",string.byte(c))
        end)
        return '"'..text..'"'
    end
    if t=="number" or t=="boolean" or t=="nil" then return tostring(v) end
    return "<"..t..">"
end
local identities={}
local function identity(v)
    local t=type(v)
    if t=="string" or t=="number" or t=="boolean" or t=="nil" then return scalar(v) end
    -- Session-local object tokens only. Different ui64 wrappers may represent the same native item.
    for i=1,#identities do if rawequal(identities[i],v) then return "<"..t.."#"..i..">" end end
    if #identities>=512 then return "<"..t..":untracked>" end
    identities[#identities+1]=v;return "<"..t.."#"..#identities..">"
end
local function dump_function(module,name,fn)
    local key=module.."."..name
    if type(string.dump)~="function" then log("SKIP "..key.." string.dump-unavailable");return end
    local ok,data=pcall(string.dump,fn)
    if not ok or type(data)~="string" then log("SKIP "..key.." not-dumpable");return end
    if #data>32768 then log("SKIP "..key.." function-over-32768-bytes");return end
    if S.bytes+#data>393216 then log("SKIP "..key.." total-byte-budget");return end
    S.bytes=S.bytes+#data
    log("BLOB-BEGIN "..key.." "..#data)
    local a,b=1,0
    for offset=1,#data,96 do
        local hex={}
        for i=offset,math.min(offset+95,#data) do
            local byte=string.byte(data,i)
            a=(a+byte)%65521;b=(b+a)%65521
            hex[#hex+1]=string.format("%02x",byte)
        end
        log("BLOB-CHUNK "..key.." "..(offset-1).." "..table.concat(hex))
    end
    log("BLOB-END "..key.." "..string.format("%08x",b*65536+a))
end
local function snapshot_table(path,t,depth,budget)
    if budget.left<=0 or depth>2 then return end
    local count=0
    for k,v in next,t do
        count=count+1;if count>160 then log("STATE-LIMIT "..path);break end
        local kind=type(k)
        if label(k) or (kind=="number" and k>=1 and k<=8 and k%1==0) then
            budget.left=budget.left-1;if budget.left<0 then return end
            local field=path.."."..tostring(k)
            log("STATE "..field.." "..identity(v))
            if type(v)=="table" and depth<2 then snapshot_table(field,v,depth+1,budget) end
        end
    end
end
local function snapshot(module)
    local m=rawget(G,module)
    if type(m)~="table" then return end
    local budget={left=100}
    log("SNAPSHOT-BEGIN "..module)
    -- No getters or list methods are invoked: only existing module table fields.
    for _,name in ipairs(keys(m,160)) do
        if string.sub(name,1,2)=="m_" then
            local value=rawget(m,name)
            log("STATE "..module.."."..name.." "..identity(value))
            if type(value)=="table" then snapshot_table(module.."."..name,value,0,budget) end
        end
        if budget.left<=0 then break end
    end
    log("SNAPSHOT-END "..module)
end
local function attach_inventory(m)
    for _,name in ipairs({"on_window_event","on_button_event_selection","on_inputdeviceaction_event","on_editbox_event"}) do
        local fn=rawget(m,name)
        if type(fn)=="function" and (not S.hooks[name] or S.hooks[name].module~=m) then
            local replacement=function(...)
                -- Run the original naturally-triggered callback, preserving all arguments/results/errors.
                local result=pack(fn(...))
                if S.active and S.events<12 then
                    S.events=S.events+1
                    local event=scalar(select(1,...))
                    local ok=pcall(function()
                        log("EVENT "..name.." arg1="..event)
                        S.collect();snapshot("inventory_win");snapshot("ledger_win");snapshot("player_inventory_manager")
                    end)
                    if not ok then pcall(log,"OBSERVER-ERROR inspection stopped for this event") end
                end
                return unpacked(result)
            end
            S.hooks[name]={module=m,original=fn,replacement=replacement}
            m[name]=replacement
        end
    end
end
local targets={"inventory_win","player_inventory_manager","name_win","uixml_helper","menu_tools","ledger_win"}
local utility={build_button_tree=true,create_button_tree=true,launch_into_button=true,close_child=true,handle_button_tree_input=true,init=true,create_standard_list=true,create_tabbed_title_bar=true,create_menu_button_helper=true,set_reminder=true,button_set_text=true,
    button_set_generic=true,button_set_state=true,on_editbox_event=true,handle_input=true,
    on_inputdeviceaction_event=true,on_window_event=true}
function S.collect()
    if not S.active then return end
    -- Read closure code from the existing native tree without calling methods.
    local ledger=rawget(G,"ledger_win")
    local tree=type(ledger)=="table" and rawget(ledger,"m_button_tree")
    if type(tree)=="table" then
        S.tree_functions=S.tree_functions or {}
        for _,name in ipairs(keys(tree,128))do
            local value=rawget(tree,name)
            if type(value)=="function" and not S.tree_functions[name]then
                S.tree_functions[name]=true;dump_function("ledger_tree",name,value)
            end
        end
    end
    for _,module in ipairs(targets) do
        local m=rawget(G,module)
        if type(m)=="table" then
            local state=S.seen[module]
            local changed=false
            if not state then
                changed=true
                state={functions={},fields={},exported=0}
                S.seen[module]=state;log("MODULE "..module)
            end
            -- Circular requires expose _M/_NAME placeholders before function bodies
            -- exist. Rescan on later triggers and export each function name once.
            for _,name in ipairs(keys(m,256)) do
                local value=rawget(m,name)
                local h=S.hooks[name]
                if h and h.module==m and value==h.replacement then value=h.original end
                local kind=type(value)
                if state.fields[name]~=kind then
                    changed=true
                    state.fields[name]=kind;log("FIELD "..module.."."..name.." "..kind)
                end
                if kind=="function" and not state.functions[name]
                    and ((module~="ledger_win" and module~="menu_tools") or utility[name]) then
                    state.functions[name]=true
                    if state.exported<96 then
                        state.exported=state.exported+1;dump_function(module,name,value)
                    else log("SKIP "..module.."."..name.." module-function-budget") end
                end
            end
            if module=="inventory_win" then attach_inventory(m) end
            if changed then log("MODULE-END "..module.." functions="..state.exported) end
        end
    end
end
function S.detach()
    S.active=false
    for name,h in next,S.hooks do
        if h.module[name]==h.replacement then h.module[name]=h.original end
    end
    identities={}
end
log("BEGIN version="..S.version)
for _,api in ipairs({"WINDOW","UIXML_ID"}) do log("CAPABILITY "..api.." "..type(rawget(G,api))) end
local W=rawget(G,"WINDOW")
if type(W)=="table" then
    for _,name in ipairs({"create_window","get_editbox_text","set_editbox_text_limit",
        "populate_edit_box","set_tabnavwin_selected_index","get_active_nav_tab_id_string"}) do
        log("CAPABILITY WINDOW."..name.." "..type(rawget(W,name)))
    end
end
S.collect()
log("READY Navigation capture: open inventory, enter Primary Weapon, Back, enter Armor, Back. No console command needed.")
return S
