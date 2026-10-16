-- Run with a writable output directory argument. Game APIs must never be called.
local real_print=print
local lines={}
print=function(line) lines[#lines+1]='[LUA] '..line end
local function forbidden() error('Undocumented game API called') end
WINDOW=setmetatable({get_editbox_text=forbidden,create_window=forbidden,
 populate_edit_box=forbidden},{__index=forbidden})
UIXML_ID=forbidden
local opaque=setmetatable({},{__tostring=forbidden})
local events=0
local original=function(event,window,...)
 events=events+1
 if event=='FAIL' then error('original error') end
 return nil,window,select('#',...)
end
local getter=function() error('Inventory getter must not be called') end
inventory_win={on_window_event=original,on_button_event_selection=original,
 on_editbox_event=original,on_inputdeviceaction_event=original,get_selected_item=getter,
 m_rows={{id=opaque,name='Duplicate',quantity=1},{id={},name='Duplicate',quantity=1}},
 m_selected=1,m_nested={loop={}}}
inventory_win.m_nested.loop=inventory_win.m_nested
player_inventory_manager={m_items=inventory_win.m_rows,get_items=getter}
name_win={init=function() error('Name window must not be opened') end}
menu_tools={create_standard_list=getter,unrelated=getter}
ledger_win={set_reminder=getter}
local expected=string.dump(getter)
local S=dofile('mods/InventoryPlusProbe/probe.lua')
assert(events==0 and inventory_win.m_selected==1 and #inventory_win.m_rows==2)
local wrapper=inventory_win.on_window_event
local before=#lines
assert(dofile('mods/InventoryPlusProbe/probe.lua')==S and inventory_win.on_window_event==wrapper)
assert(#lines==before) -- no duplicate dump or wrapper
local a,b,c=wrapper('SHOW',opaque,1,nil,3)
assert(a==nil and rawequal(b,opaque) and c==3)
local ok,err=pcall(wrapper,'FAIL',{})
assert(not ok and string.find(err,'original error',1,true))
-- New module discovered after a later framework trigger.
local old_name=name_win
name_win=old_name
local prior_rows=inventory_win.m_rows
for i=1,20 do inventory_win.on_button_event_selection('SELECT',opaque) end
assert(events==22 and inventory_win.m_rows==prior_rows and S.events==12)
assert(inventory_win.get_selected_item==getter and name_win.init~=nil)
-- Interference with diagnostic output cannot break a successful native callback.
S.events=0
print=forbidden
local x,y,z=wrapper('SHOW',opaque)
assert(x==nil and y==opaque and z==0)
print=function(line)lines[#lines+1]='[LUA] '..line end
S.detach();assert(not S.active and inventory_win.on_window_event==original)
assert(inventory_win.on_button_event_selection==original)
local path=assert(arg[1])
local file=assert(io.open(path..'/probe.log','wb'));file:write(table.concat(lines,'\n')..'\n');file:close()
file=assert(io.open(path..'/expected.bin','wb'));file:write(expected);file:close()
local data=table.concat(lines,'\n')
assert(string.find(data,'SKIP')==nil) -- all exported fixture functions are Lua
assert(string.find(data,'EVENT on_button_event_selection',1,true))
assert(string.find(data,'CAPABILITY WINDOW.get_editbox_text function',1,true))
assert(not string.find(data,'BLOB-BEGIN menu_tools.unrelated',1,true))
local first=string.match(data,'STATE inventory_win%.m_rows%.1%.id (<table#%d+>)')
local second=string.match(data,'STATE inventory_win%.m_rows%.2%.id (<table#%d+>)')
assert(first and second and first~=second) -- same-name rows retain distinct object observations
print=real_print
print('Inventory probe: observation, event budget, identity, errors and detachment passed')
