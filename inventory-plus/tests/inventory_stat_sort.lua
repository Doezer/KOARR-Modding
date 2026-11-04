math.floor=nil
local logs,specs,fired={}, {}, {}
print=function(s)logs[#logs+1]=s end
local values={[10]=5,[20]=40,[30]=nil,[40]=40}
InventoryPlusNative={self_test=function(s)return s end,fold=string.lower,idle=function()return true end,
 poll=function(s)local v=fired[s];fired[s]=nil;return v and s or nil end,
 item_name=function(id)return 'item'..id end,
 stat=function(handle,spec)specs[spec]=true;local v=values[handle];if v==nil then return nil end;return tostring(v) end,
 stats=function()return 'Sword','1,2','3,4','5,6','7,8' end}
ACTOR={is_valid=function()return true end}
WINDOW={is_visible=function()return true end,set_label_text=function()end}
ledger_win={set_reminder=function()end}
local rows={{header_id='Gear',header_text=1,len=4},{item_id=10},{item_id=20},{item_id=30},{item_id=40}}
inventory_win={m_inited=true,m_window={},m_list_wrapper={},m_curr_mode='replace',m_selected_slot=2627341,
 m_button_definitions={[2627341]={},[1070770]={},[123]={}},m_category_status={Gear={collapsed=false}},m_last_set={},
 m_list={get_selected=function()return 1 end,set_selected=function()end},
 get_selected_item=function()return 20 end,
 update_selected_window=function()end,on_window_event=function()end,on_update_event=function()end,
 get_surplus_inventory=function()
  local copy={};for i,r in ipairs(rows)do copy[i]=r end
  inventory_win.m_cur_categories={Gear=1};return copy,nil,'snapshot'
 end}
inventory_win.rebuild_list_win=function()inventory_win.m_last_set=inventory_win.get_surplus_inventory()end
dofile('mods/InventoryPlus/model.lua')
local S=dofile('mods/InventoryPlus/inventory_plus.lua')
local I=inventory_win
local function order()local ids={};for i=2,#I.m_last_set do ids[#ids+1]=I.m_last_set[i].item_id end;return table.concat(ids,',')end
-- Weapon slot: native, A-Z, Z-A, damage, back to native.
assert(S.cycle_sort() and S.order=='az')
assert(S.cycle_sort() and S.order=='za')
assert(S.cycle_sort() and S.order=='dmg' and specs.d001)
assert(order()=='20,40,10,30') -- high to low, tie by name, unknown (30) last
assert(S.cycle_sort() and S.order=='native')
-- A stat order never survives a category it does not apply to.
S.order='dmg';I.m_selected_slot=1070770;I.rebuild_list_win()
assert(S.order=='az')
S.order='native'
for _=1,3 do S.cycle_sort()end
assert(S.order=='arm' and specs.a001)
-- Non-gear categories offer only the name orders.
I.m_selected_slot=123;S.order='native'
for _=1,3 do S.cycle_sort()end
assert(S.order=='native')
-- Ctrl+D logs both tables without changing the view.
I.m_selected_slot=2627341;fired['Ctrl+D']=true
local before=order();assert(S.dump_stats() and order()==before)
local joined=table.concat(logs,'\n')
assert(joined:find('damage raw    =1,2',1,true) and joined:find('provisional sort keys',1,true))
S.detach()
print=io.write
print('Stat sort: weapon/armor orders, unknown-last, category reset and dump passed\n')
