local actions,button_events,frames,ledger_frames=0,0,0,0
local owned={};local capture=false
InventoryPlusNavigationV2={create=function()
 return {windows={},update=function()capture=false end,close=function()end,
 detach=function()capture=false end,cancel=function()end,
 owns_click=function()return capture end,
 event=function(event,window)
  if capture then return true end
  if window==owned then capture=true;return true end
  return false
 end}
end}
local chord=false
InventoryPlusNative={self_test=function(s)return s end,fold=string.lower,
 held=function(s)return chord and s or nil end,poll=function()end,idle=function()return true end,item_name=function()return 'Item'end}
WINDOW={is_visible=function()return true end}
ledger_win={on_update_event=function()ledger_frames=ledger_frames+1;return nil,'frame'end,
 on_button_event_selection=function()button_events=button_events+1 end,
 on_inputdeviceaction_event=function()actions=actions+1 end}
inventory_win={m_inited=true,m_window={},m_list_wrapper={},m_curr_mode='replace',
 m_selected_slot=1,m_button_definitions={[1]={}},m_last_set={},
 on_window_event=function()end,on_update_event=function()frames=frames+1 end,
 handle_input=function()actions=actions+1 end,equip_selected=function()actions=actions+1 end,
 on_button_event_selection=function()button_events=button_events+1 end}
dofile('mods/InventoryPlus/model.lua')
local S=dofile('mods/InventoryPlus/inventory_plus.lua')
ledger_win.on_button_event_selection('DOWN',owned)
assert(capture and button_events==0) -- intercept before native ledger tree
ledger_win.on_button_event_selection('UP',{})
inventory_win.on_button_event_selection('UP',{})
assert(button_events==0)
local input={info='a'};inventory_win.handle_input(input)
inventory_win.equip_selected();ledger_win.on_inputdeviceaction_event(nil,'a')
inventory_win.on_update_event()
assert(input.handled and actions==0 and frames==0)
ledger_win.on_inputdeviceaction_event(nil,'b')
assert(actions==1) -- Back is never locked by pointer capture
local a,b=ledger_win.on_update_event();assert(a==nil and b=='frame'and ledger_frames==1)
assert(not capture)
ledger_win.on_button_event_selection('DOWN',{})
inventory_win.equip_selected();inventory_win.on_update_event()
assert(button_events==1 and actions==2 and frames==1)
-- The game's own digit hotkeys (1/2 equip) must not act while a Ctrl+digit chord is held.
chord=true;local before_actions=actions
ledger_win.on_inputdeviceaction_event(nil,'1')
local digit={info='1'};inventory_win.handle_input(digit);inventory_win.equip_selected()
assert(actions==before_actions and digit.handled)
ledger_win.on_inputdeviceaction_event(nil,'b');assert(actions==before_actions+1) -- Back is never swallowed
chord=false
ledger_win.on_inputdeviceaction_event(nil,'1');assert(actions==before_actions+2) -- plain 1 stays native
S.detach()
print('Tab click isolation: ledger interception, retargeted release, action suppression, Back and normal-input recovery passed')
