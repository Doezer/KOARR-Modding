math.floor=nil
local logs,specs,fired,calls={}, {}, {}, {}
print=function(s)logs[#logs+1]=s end
InventoryPlusNative={self_test=function(s)return s end,fold=string.lower,idle=function()return true end,
 poll=function(s)local v=fired[s];fired[s]=nil;return v and s or nil end,
 item_name=function(id)return 'item'..id end,
 stat=function(handle,spec)specs[spec]=true;local v=({[10]=5,[20]=40,[40]=40})[handle];if v==nil then return nil end;return tostring(v) end,
 has_stats=function()return 1 end,
 stats=function()return 'Sword','1,2','3,4','5,6','7,8' end}
local cost={[10]=300,[20]=50,[30]=900,[40]=50}
local function attr(table_)return function(h)if h==40 then error('unreadable')end;return table_[h] or 0 end end
ACTOR={is_valid=function()return true end,
 get_item_cost=function(h)calls.cost=(calls.cost or 0)+1;return cost[h] end,
 get_might_requirement=function(h)calls.level=(calls.level or 0)+1;return attr({[20]=8})(h)end,
 get_finesse_requirement=attr({[10]=8}),get_intellect_requirement=attr({}),get_level_requirement=attr({}),
 get_item_level=function(h)return 7 end,
 set_item_cost=function()error('a setter must never be called')end}
WINDOW={is_visible=function()return true end,set_label_text=function()end}
ledger_win={set_reminder=function()end}
local rows={{header_id='Gear',header_text=1,len=4},{item_id=10},{item_id=20},{item_id=30},{item_id=40}}
inventory_win={m_inited=true,m_window={},m_list_wrapper={},m_curr_mode='replace',m_selected_slot=2627341,
 m_button_definitions={[2627341]={},[1070770]={},[123]={},[7304644]={}},m_category_status={Gear={collapsed=false}},m_last_set={},
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
local function cycle_to(target)for _=1,8 do if S.order==target then return true end;S.cycle_sort()end;return false end
-- Weapon slot: native, A-Z, Z-A, damage, requirement, value, back to native.
local seen={}
for _=1,6 do S.cycle_sort();seen[#seen+1]=S.order end
assert(table.concat(seen,',')=='az,za,dmg,req,val,native',table.concat(seen,','))
assert(cycle_to('dmg') and specs.d001)
assert(order()=='20,40,10,30') -- high to low, tie by name, unknown (30) last
assert(cycle_to('req'))
assert(order()=='10,20,30,40') -- 8 (finesse) and 8 (might) tie by name; 0 is known; unreadable (40) last
assert(cycle_to('val'))
assert(order()=='30,10,20,40') -- 900, 300, then the 50s tie by name
assert(calls.cost and calls.cost>0 and calls.level and calls.level>0)
-- A stat order never survives a category it does not apply to.
S.order='dmg';I.m_selected_slot=1070770;I.rebuild_list_win()
assert(S.order=='az')
S.order='native';seen={}
for _=1,6 do S.cycle_sort();seen[#seen+1]=S.order end
assert(table.concat(seen,',')=='az,za,arm,req,val,native',table.concat(seen,','))
assert(specs.a001)
-- Consumables offer value only; unknown categories offer only the name orders.
I.m_selected_slot=7304644;S.order='native';seen={}
for _=1,4 do S.cycle_sort();seen[#seen+1]=S.order end
assert(table.concat(seen,',')=='az,za,val,native',table.concat(seen,','))
I.m_selected_slot=123;S.order='native';seen={}
for _=1,3 do S.cycle_sort();seen[#seen+1]=S.order end
assert(table.concat(seen,',')=='az,za,native')
-- Ctrl+D logs both tables and the getter values without changing the view.
I.m_selected_slot=2627341;fired['Ctrl+D']=true
local before=order();assert(S.dump_stats() and order()==before)
local joined=table.concat(logs,'\n')
assert(joined:find('damage raw    =1,2',1,true) and joined:find('provisional sort keys',1,true))
assert(joined:find('get_item_cost=50 get_level_requirement=0 get_item_level=7',1,true))
assert(joined:find('requirements might=8 finesse=0 intellect=0',1,true))
-- The footer shares its row with native buttons: no state may exceed 34 characters.
for _,o in ipairs({'native','az','za','dmg','arm','req','val'})do
 for _,q in ipairs({'','a','frostbitten greatsword of doom'})do
  for _,m in ipairs({0,5})do
   S.order=o;S.query=q;S.matched=m;S.total=64
   local text=S.footer_text();assert(#text<=34,text)
  end
 end
end
S.detach()
print=io.write
print('Stat sort: damage/armor/level/value orders, unknown-last, category reset and dump passed\n')
