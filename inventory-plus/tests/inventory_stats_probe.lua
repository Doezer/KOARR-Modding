local calls,logs,frames,polls=0,{},0,0
local real_print=print
print=function(s)logs[#logs+1]=s end
InventoryPlusStatsNative={self_test=function(s)return s=='InventoryPlusStats 0.1.0' and 1 or 0 end,
 poll=function()polls=polls+1;return polls==2 end,
 stats=function(h)calls=calls+1;if h=='bad' then error('no') end;return 'Sword','1,2','3,4','5,6','7,8' end}
ACTOR={is_valid=function(h)return h~='stale' end}
WINDOW={is_visible=function()return true end}
local selected={}
local original=function()frames=frames+1 end
inventory_win={m_inited=true,m_window={},m_selected_slot=7,on_update_event=original,get_selected_item=function()return selected end}
local S=dofile('mods/InventoryPlusStatsProbe/stats_probe.lua')
inventory_win.on_update_event();assert(calls==0 and frames==1) -- no key
inventory_win.on_update_event();assert(calls==1 and frames==2) -- Ctrl+D
local joined=table.concat(logs,'\n')
assert(joined:find('damage raw    =1,2',1,true) and joined:find('armor  scaled =7,8',1,true))
selected=nil;polls=1;inventory_win.on_update_event();assert(calls==1) -- no selection never reaches native
S.detach();assert(inventory_win.on_update_event==original)
print=real_print
print('Stats probe: key dump, no-selection guard and detach passed')
