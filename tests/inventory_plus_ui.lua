-- Reproduce the game's restricted runtime and module loading order.
math.floor=nil
loadfile=function()error('No nested asset loading at startup')end
package.loadlib=function()error('No nested native loading')end
local fired,idle,launch_fail=false,true,false
local logs={};print=function(s)logs[#logs+1]=s end
InventoryPlusNative={self_test=function(s)return s end,
 poll=function(s)assert(s=='Ctrl+F');local v=fired;fired=false;return v and s or nil end,
 idle=function(s)return idle and s or nil end}
local original_updates,actions,ledger_actions,launches=0,0,0,0
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
local S=dofile('mods/InventoryPlus/ui_trial.lua')
assert(S.enabled and #S.hooks==0 and launches==0)
local I=inventory_win
I.m_inited=true;I.m_window={};I.m_curr_mode='replace'
local rows={{item_id=10},{item_id=20}};I.m_last_set=rows
I.on_window_event=function(event)if event=='SHOW'then I.button_tree_callback('enter',123)end;return nil,'window'end
I.on_update_event=function()original_updates=original_updates+1;return nil,'update',nil end
I.button_tree_callback=function()ledger_win.set_reminder(123);return nil,'category'end
I.handle_input=function(input)actions=actions+1;input.handled=true;return nil,'action'end
for _,name in ipairs({'on_button_event_selection','handle_drop','equip_selected','unequip_selected',
 'queue_for_autosell','destroy_selected_item','confirm_destroy_junk'})do
 I[name]=function()actions=actions+1;return nil,'native action'end
end
name_win={m_inited=false,launch=function(title,text,localized,limit,callback,cant_cancel)
 assert(title=='Search items' and localized==false and limit==64 and cant_cancel==false)
 launches=launches+1
 if launch_fail then error('UI creation failure')end
 name_win.m_callback=callback;name_win.m_inited=true;name_win.initial=text
end,cancel_name=function()name_win.m_inited=false;name_win.m_callback(name_win.initial,true)end}
assert(dofile('mods/InventoryPlus/ui_trial.lua')==S)
local hook_count=#S.hooks
assert(dofile('mods/InventoryPlus/ui_trial.lua')==S and #S.hooks==hook_count)
local a,b=I.on_window_event('SHOW');assert(a==nil and b=='window')
assert(footer.text=='Ctrl+F: Search (UI trial)')
assert(WINDOW.set_label_text==plain and WINDOW.set_label_text_formatted==formatted)
local x,y,z=I.on_update_event();assert(x==nil and y=='update'and z==nil)
local args={info='a'};I.handle_input(args);assert(actions==1 and args.handled)
-- Shortcut is intercepted before the native ledger can dispatch an item action.
fired=true;ledger_win.on_inputdeviceaction_event(nil,'a')
assert(launches==1 and S.editing and ledger_actions==0)
assert(not S.open_search())
local before=actions;local updates=original_updates
for _,name in ipairs({'handle_input','on_button_event_selection','handle_drop','equip_selected',
 'unequip_selected','queue_for_autosell','destroy_selected_item','confirm_destroy_junk'})do
 I[name]({info='a'})
end
ledger_win.on_inputdeviceaction_event(nil,'a');I.on_update_event()
assert(actions==before and ledger_actions==0 and original_updates==updates)
-- Native confirmation callback runs before window destruction; guard remains.
name_win.m_callback('Frost sword',false);assert(S.query=='Frost sword' and S.editing and S.closing)
idle=false;name_win.m_inited=false;I.on_update_event();assert(S.editing)
idle=true;I.on_update_event();assert(not S.editing and original_updates==updates)
assert(footer.text=='Search entered: Frost sword | Ctrl+F: Edit (UI trial)')
I.on_update_event();assert(original_updates==updates+1)
I.equip_selected();assert(actions==before+1)
-- Cancel leaves previous text intact and also waits for release.
assert(S.open_search());name_win.cancel_name();I.on_update_event()
assert(not S.editing and S.query=='Frost sword')
assert(I.m_last_set==rows and rows[1].item_id==10 and rows[2].item_id==20)
-- Direct inventory dispatch can also receive the shortcut before a frame tick.
local input={info='a'};before=actions;fired=true;I.handle_input(input)
assert(S.editing and input.handled and actions==before)
name_win.cancel_name();I.on_update_event();assert(not S.editing)
-- Do not steal the native name dialog or search while inventory is hidden.
name_win.m_inited=true;assert(not S.open_search());name_win.m_inited=false
visible=false;assert(not S.open_search());visible=true
I.m_curr_mode='confirm';assert(not S.open_search());I.m_curr_mode='replace'
-- A failed launch must release the guard so the player retains inventory input.
launch_fail=true;assert(not S.open_search() and not S.editing);launch_fail=false
-- An original reminder failure must not leave shared WINDOW setters replaced.
local failed=ledger_win.set_reminder
ledger_win.set_reminder=function()error('Reminder failed')end
assert(not pcall(I.button_tree_callback))
assert(WINDOW.set_label_text==plain and WINDOW.set_label_text_formatted==formatted)
ledger_win.set_reminder=failed
I.on_window_event('HIDE');assert(footer.text=='Localized 123')
S.detach();assert(ledger_win.set_reminder==original_reminder)
assert(I.m_last_set==rows and not S.enabled)
-- Neither a mismatched native bridge nor a missing helper may launch UI.
InventoryPlusNative.self_test=function()return 'wrong bridge'end
S=dofile('mods/InventoryPlus/ui_trial.lua');assert(not S.open_search() and not S.editing);S.detach()
InventoryPlusNative=nil
assert(dofile('mods/InventoryPlus/ui_trial.lua')==false)
