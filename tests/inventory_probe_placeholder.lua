-- Reproduce circular module loading from the real log: placeholders precede bodies.
local lines={};local real_print=print
print=function(s)lines[#lines+1]='[LUA] '..s end
inventory_win={_NAME='inventory_win'}
ledger_win={_NAME='ledger_win'}
menu_tools={create_standard_list=function()return {}end}
local S=dofile('mods/InventoryPlusProbe/probe.lua')
assert(S.seen.inventory_win.exported==0 and S.hooks.on_window_event==nil)
local original=function()return nil,'original'end
inventory_win.on_window_event=original
inventory_win.get_selected_item=function()return nil end
inventory_win.m_items={{id=1,name='Example'}}
ledger_win.set_reminder=function()return 'reminder'end
S.collect()
assert(S.seen.inventory_win.exported==2 and S.seen.ledger_win.exported==1)
local wrapper=inventory_win.on_window_event
assert(wrapper~=original)
local before=#lines
S.collect();S.collect()
assert(#lines==before and inventory_win.on_window_event==wrapper)
local a,b=wrapper('SHOW');assert(a==nil and b=='original')
local data=table.concat(lines,'\n')
local _,count=string.gsub(data,'BLOB%-BEGIN inventory_win%.on_window_event ','')
assert(count==1)
local file=assert(io.open(assert(arg[1])..'/placeholder.log','wb'))
file:write(data..'\n');file:close()
S.detach();assert(inventory_win.on_window_event==original)
print=real_print
print('Inventory probe: late-populated module functions exported once and observed after load')
