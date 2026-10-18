-- Native contracts are simulated; actual UI focus/OS Unicode remain game checks.
math.floor=nil
loadfile=function()error('No nested asset loading at startup')end
package.loadlib=function()error('No nested native loading')end
local fired,idle,launch_fail={},true,false
local logs={};print=function(s)logs[#logs+1]=s end
InventoryPlusNative={item_name=function()error("No inventory yet")end,self_test=function(s)return s end,
 poll=function(s)local v=fired[s];fired[s]=nil;return v and s or nil end,
 idle=function(s)return idle and s or nil end,fold=string.lower}
local original_updates,actions,ledger_actions,launches=0,{},0,0
local visible=true
local footer={text='Original hint'}
WINDOW={is_visible=function()return visible end,
 set_label_text=function(w,text)w.text=text end,
 set_label_text_formatted=function(w,id)w.text='Localized '..tostring(id);return nil,'label' end}
local plain,formatted=WINDOW.set_label_text,WINDOW.set_label_text_formatted
ledger_win={set_reminder=function(id)WINDOW.set_label_text_formatted(footer,id);return nil,'reminder'end,
 on_inputdeviceaction_event=function()ledger_actions=ledger_actions+1;return nil,'ledger'end}
local original_reminder=ledger_win.set_reminder
inventory_win={}
dofile('mods/InventoryPlus/model.lua')
local S=dofile('mods/InventoryPlus/inventory_plus.lua')
assert(S.enabled and #S.hooks==0 and launches==0)
local I=inventory_win
I.m_inited=true;I.m_window={};I.m_curr_mode='replace';I.m_selected_slot=123
I.m_button_definitions={[123]={},[456]={}}
I.m_category_status={Weapon={collapsed=false},Potions={collapsed=true}}
local rows={{header_id='Weapon',header_text=100,len=3},{item_id=10,stack=2},{item_id=20},{item_id=30},
 {header_id='Potions',header_text=200,len=1},{item_id=40}}
local valid={[10]=true,[20]=true,[30]=true,[40]=true}
local names={[10]='Frost Sword',[20]='Shine',[30]='Frost Sword',[40]='Healing Potion'}
ACTOR={is_valid=function(id)return valid[id]end,
 get_actor_display_name=function()error('Actor display names are not inventory names')end}
InventoryPlusNative.item_name=function(id)return names[id]end
I.m_list={selected=3,get_selected=function(self)return self.selected end,
 set_selected=function(self,index)self.selected=index end}
I.get_selected_item=function(header)
 local row=I.m_last_set and I.m_last_set[I.m_list.selected]
 return row and (header and row.header_id or row.item_id)
end
I.get_surplus_inventory=function()
 local result={};local collapsed=false;I.m_cur_categories={}
 for _,row in ipairs(rows)do
  if row.header_id then
   collapsed=I.m_category_status[row.header_id].collapsed
   result[#result+1]=row;I.m_cur_categories[row.header_id]=#result
  elseif not collapsed and valid[row.item_id]then result[#result+1]=row end
 end
 return result,nil,'snapshot'
end
local detail_history={}
I.update_selected_window=function()I.details=I.get_selected_item();detail_history[#detail_history+1]=I.details or false end
I.update_visibility=function()I.buttons=I.get_selected_item()end
I.update_rose=function()end
I.rebuild_list_win=function()
 I.m_last_set=I.get_surplus_inventory()
 if I.force_native_selection then I.m_list.selected=I.force_native_selection end
 if not I.m_list.selected or I.m_list.selected>#I.m_last_set then I.m_list.selected=1 end
 I.update_selected_window();return nil,'rebuilt'
end
I.rebuild_list_win()
I.on_window_event=function(event)if event=='SHOW'then I.button_tree_callback('enter',123)end;return nil,'window'end
I.on_update_event=function()original_updates=original_updates+1;return nil,'update',nil end
I.button_tree_callback=function()I.rebuild_list_win();ledger_win.set_reminder(123);return nil,'category'end
I.handle_input=function(input)actions[#actions+1]=I.get_selected_item();input.handled=true;return nil,'action'end
for _,name in ipairs({'on_button_event_selection','handle_drop','equip_selected','unequip_selected',
 'queue_for_autosell','destroy_selected_item','confirm_destroy_junk'})do
 I[name]=function()actions[#actions+1]=I.get_selected_item();return nil,'native action'end
end
name_win={m_inited=false,launch=function(title,text,localized,limit,callback,cant_cancel)
 assert(title=='Search items' and localized==false and limit==64 and cant_cancel==false)
 launches=launches+1;if launch_fail then error('UI creation failure')end
 name_win.m_callback=callback;name_win.m_inited=true;name_win.initial=text
end,cancel_name=function()name_win.m_inited=false;name_win.m_callback(name_win.initial,true)end}
assert(dofile('mods/InventoryPlus/inventory_plus.lua')==S)
local hook_count=#S.hooks
assert(dofile('mods/InventoryPlus/inventory_plus.lua')==S and #S.hooks==hook_count)
local a,b=I.on_window_event('SHOW');assert(a==nil and b=='window')
assert(footer.text=='Ctrl+F: Find | Ctrl+S: Sort')
assert(WINDOW.set_label_text==plain and WINDOW.set_label_text_formatted==formatted)
local x,y,z=I.on_update_event();assert(x==nil and y=='update'and z==nil)
-- Name sort moves rows but keeps the selected exact handle, including duplicates.
local detail_count=#detail_history
fired['Ctrl+S']=true;ledger_win.on_inputdeviceaction_event(nil,'a')
assert(S.order=='az' and I.get_selected_item()==20 and I.m_list.selected==4)
for i=detail_count+1,#detail_history do assert(detail_history[i]==20)end
I.equip_selected();assert(actions[#actions]==20)
assert(S.cycle_sort() and I.get_selected_item()==20 and I.m_list.selected==2)
assert(S.cycle_sort() and S.order=='native' and I.get_selected_item()==20)
I.m_list.selected=4;assert(I.get_selected_item()==30)
fired['Ctrl+F']=true;ledger_win.on_inputdeviceaction_event(nil,'a')
assert(launches==1 and S.editing and ledger_actions==0 and not S.open_search())
local before=#actions;local updates=original_updates
for _,name in ipairs({'handle_input','on_button_event_selection','handle_drop','equip_selected',
 'unequip_selected','queue_for_autosell','destroy_selected_item','confirm_destroy_junk'})do I[name]({info='a'})end
ledger_win.on_inputdeviceaction_event(nil,'a');I.on_update_event()
assert(#actions==before and ledger_actions==0 and original_updates==updates)
name_win.m_callback(' frost ',false)
assert(S.query=='' and S.pending_query==' frost ' and S.editing and S.closing)
idle=false;name_win.m_inited=false;I.on_update_event();assert(S.editing)
idle=true;I.on_update_event();assert(not S.editing and original_updates==updates)
assert(S.query=='frost' and S.matched==2 and S.total==4)
assert(I.get_selected_item()==30 and I.m_list.selected==3 and I.m_last_set[3]==rows[4])
assert(I.m_cur_categories.Potions==4 and I.m_last_set[1].len==2 and rows[1].len==3)
assert(not I.m_category_status.Potions.collapsed) -- search expands original UI categories
assert(footer.text=='frost 2/4 | Esc: Clear' and #footer.text<40)
I.on_update_event();assert(original_updates==updates+1)
I.equip_selected();assert(actions[#actions]==30)
-- Bulk junk destruction must not act on items concealed by a name filter.
before=#actions;I.confirm_destroy_junk();assert(#actions==before)
assert(S.open_search());name_win.cancel_name();I.on_update_event();assert(not S.editing and S.query=='frost')
-- Collapse still works inside search; all matching counts stay accurate.
I.m_category_status.Weapon.collapsed=true;I.rebuild_list_win()
assert(S.matched==2 and #I.m_last_set==2 and I.m_cur_categories.Potions==2)
assert(I.get_selected_item()==nil)
I.equip_selected();assert(#actions==before)
-- Esc clears only the query and restores pre-search category expansion.
ledger_win.on_inputdeviceaction_event(nil,'b')
assert(S.query=='' and ledger_actions==0 and not I.m_category_status.Weapon.collapsed and I.m_category_status.Potions.collapsed)
assert(#I.m_last_set==5)
-- A held/repeated Back must not clear and close the inventory on the same press.
idle=false;ledger_win.on_inputdeviceaction_event(nil,'b');I.on_update_event()
assert(S.back_guard and ledger_actions==0)
idle=true;I.on_update_event();assert(not S.back_guard)
-- Empty results hide details/actions; another category cannot become a wrong item.
assert(S.set_query('absent') and S.matched==0 and I.get_selected_item()==nil)
assert(string.find(footer.text,'No matches',1,true))
before=#actions;I.destroy_selected_item();assert(#actions==before)
S.clear_search()
-- A removed item is invalidated before an action, then a fresh rebuild selects a survivor.
I.m_list.selected=4;assert(S.set_query('frost') and I.get_selected_item()==30)
valid[30]=nil;assert(I.get_selected_item()==nil)
before=#actions;I.equip_selected();assert(#actions==before)
I.rebuild_list_win();assert(S.matched==1 and I.get_selected_item()==10)
-- Missing metadata restores the full native list and original category flags.
names[20]=nil;S.set_query('shine')
assert(S.query=='' and S.order=='native' and #I.m_last_set==4 and I.m_category_status.Potions.collapsed)
names[20]='Shine';valid[30]=true
-- Category changes retain the native category's default selection, rather than
-- interpreting an old row index through a newly assigned category snapshot.
S.set_query('frost');I.m_list.selected=3
I.force_native_selection=2;I.m_selected_slot=456;I.button_tree_callback('enter',456)
assert(I.get_selected_item()==10)
I.force_native_selection=nil;S.clear_search()
-- Keyboard guard also covers dispatch directly to the inventory.
local input={info='a'};before=#actions;fired['Ctrl+F']=true;I.handle_input(input)
assert(S.editing and input.handled and #actions==before)
name_win.cancel_name();I.on_update_event();assert(not S.editing)
name_win.m_inited=true;assert(not S.open_search());name_win.m_inited=false
visible=false;assert(not S.open_search());visible=true
I.m_curr_mode='confirm';assert(not S.open_search());I.m_curr_mode='replace'
launch_fail=true;assert(not S.open_search() and not S.editing);launch_fail=false
local saved_reminder=ledger_win.set_reminder
ledger_win.set_reminder=function()error('Reminder failed')end
assert(not pcall(I.button_tree_callback))
assert(WINDOW.set_label_text==plain and WINDOW.set_label_text_formatted==formatted)
ledger_win.set_reminder=saved_reminder
I.on_window_event('HIDE');assert(footer.text=='Localized 123')
S.detach();assert(ledger_win.set_reminder==original_reminder and not S.enabled)
InventoryPlusNative.self_test=function()return 'wrong bridge'end
S=dofile('mods/InventoryPlus/inventory_plus.lua');assert(not S.open_search() and not S.editing and not S.cycle_sort());S.detach()
InventoryPlusNative.self_test=function(s)return s end
InventoryPlusNative.fold=function(s)return s end
S=dofile('mods/InventoryPlus/inventory_plus.lua');assert(not S.open_search() and not S.cycle_sort());S.detach()
InventoryPlusNative=nil
assert(dofile('mods/InventoryPlus/inventory_plus.lua')==false)
