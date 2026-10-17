-- Inventory Plus 0.1.0: native search-input trial. No rows or item data change.
local function bootstrap()
local G=_G
local previous=rawget(G,'InventoryPlusTrial')
if previous and previous.enabled then previous.attach();return previous end
local function log(message)print('[InventoryPlus] '..message)end
local N=rawget(G,'InventoryPlusNative')
if type(N)~='table' or type(N.self_test)~='function' or type(N.poll)~='function' or type(N.idle)~='function' then
 log('Keyboard helper unavailable; no inventory changes installed.');return false
end
local S={enabled=true,version='0.1.0-ui-trial',hooks={},query='',editing=false,closing=false,ready=false}
G.InventoryPlusTrial=S
local function pack(...)return {n=select('#',...),...}end
local function returns(t)return unpack(t,1,t.n)end
local function wrap(module,name,make)
 if type(module)~='table' or type(module[name])~='function' then return false end
 for _,h in ipairs(S.hooks)do if h.module==module and h.name==name then return true end end
 local original=module[name];local replacement=make(original)
 module[name]=replacement
 S.hooks[#S.hooks+1]={module=module,name=name,original=original,replacement=replacement}
 return true
end
local reminder,scope
local function hint()
 return S.query=='' and 'Ctrl+F: Search (UI trial)' or ('Search entered: '..S.query..' | Ctrl+F: Edit (UI trial)')
end
local function update_hint()
 if reminder and S.enabled then reminder.write(reminder.label,hint())end
end
local function restore_hint()
 if reminder then local old=reminder;reminder=nil;old.setter(returns(old.args))end
end
local function capture(original,...)
 local W=rawget(G,'WINDOW')
 if type(W)~='table' or type(W.set_label_text)~='function' then return original(...)end
 local changed,captured={},nil
 local write=W.set_label_text
 for _,name in ipairs({'set_label_text','set_label_text_formatted','set_label_text_no_loc_fix_up','set_label_text_with_built_string'})do
  local setter=W[name]
  if type(setter)=='function' then
   local replacement=function(...)
    local args=pack(...);local result=pack(setter(...))
    if args[1] then captured={label=args[1],write=write,setter=setter,args=args}end
    return returns(result)
   end
   W[name]=replacement;changed[#changed+1]={name=name,setter=setter,replacement=replacement}
  end
 end
 local result=pack(pcall(original,...))
 for _,h in ipairs(changed)do if W[h.name]==h.replacement then W[h.name]=h.setter end end
 if not result[1] then error(result[2],0)end
 if captured then reminder=captured;update_hint()end
 return unpack(result,2,result.n)
end
local function available()
 local I,W=rawget(G,'inventory_win'),rawget(G,'WINDOW')
 return S.enabled and type(I)=='table' and I.m_inited and I.m_window
  and type(W)=='table' and type(W.is_visible)=='function' and W.is_visible(I.m_window)
  and (I.m_curr_mode=='replace' or I.m_curr_mode=='pocket')
end
function S.open_search()
 if not available() or S.editing then return false end
 local name=rawget(G,'name_win')
 if type(name)~='table' or type(name.launch)~='function' or name.m_inited then return false end
 local tutorial=rawget(G,'tutorial_win')
 if type(tutorial)=='table' and type(tutorial.is_modal_tutorial_active)=='function' and tutorial.is_modal_tutorial_active()then return false end
 local menu=rawget(G,'menu_tools')
 if type(menu)=='table' and type(menu.is_dragging)=='function' and menu.is_dragging()then return false end
 if not S.ready then
  local ok,reply=pcall(N.self_test,'InventoryPlus UI 0.1.0')
  if not ok or reply~='InventoryPlus UI 0.1.0' then log('Keyboard bridge check failed; search disabled.');return false end
  S.ready=true
 end
 S.editing=true;S.closing=false
 local callback=function(text,cancelled)
  if not S.editing or S.callback~=name.m_callback then return end
  if not cancelled and type(text)=='string' then S.query=text end
  S.closing=true
  log(cancelled and 'Search cancelled; query unchanged.' or 'Search text accepted; inventory list unchanged in this UI trial.')
 end
 S.callback=callback
 -- Original six-argument name_win contract; it creates/focuses the native modal.
 local ok,err=pcall(name.launch,'Search items',S.query,false,64,callback,false)
 if not ok then
  if name.m_inited and name.m_callback==callback and type(name.cancel_name)=='function' then pcall(name.cancel_name)end
  S.editing=false;S.closing=false;S.callback=nil
  log('Could not open search: '..tostring(err));return false
 end
 log('Native search dialog requested.');return true
end
function S.attach()
 local I=rawget(G,'inventory_win')
 if type(I)~='table' or type(I.on_update_event)~='function' or type(I.on_window_event)~='function' then return end
 wrap(rawget(G,'ledger_win'),'set_reminder',function(original)return function(...)
  if S.enabled and scope then return capture(original,...)end
  reminder=nil;return original(...)
 end end)
 wrap(I,'button_tree_callback',function(original)return function(...)
  local old=scope;scope=S.enabled
  local result=pack(pcall(original,...));scope=old
  if not result[1]then error(result[2],0)end
  return unpack(result,2,result.n)
 end end)
 wrap(I,'on_window_event',function(original)return function(event,...)
  if S.enabled and (event=='HIDE' or event=='START_CLOSE')then restore_hint()end
  if S.enabled and event=='SHOW' and not S.editing then S.query='' end
  if S.enabled and event=='SHOW' then N.poll('Ctrl+F')end
  return original(event,...)
 end end)
 -- Block the ledger's action dispatch before it reaches the native button tree.
 -- name_win's own modal handlers stay active for text, confirmation and cancel.
 wrap(rawget(G,'ledger_win'),'on_inputdeviceaction_event',function(original)return function(...)
  if S.enabled and S.editing then return end
  if available() and N.poll('Ctrl+F')then S.open_search();return end
  return original(...)
 end end)
 wrap(I,'handle_input',function(original)return function(input,...)
  if not S.editing and available() and N.poll('Ctrl+F')then
   S.open_search();if type(input)=='table'then input.handled=true end;return
  end
  if S.enabled and S.editing then if type(input)=='table'then input.handled=true end;return end
  return original(input,...)
 end end)
 for _,name in ipairs({'on_button_event_selection','on_mouse_event_scroll','on_mouse_event_tooltip',
  'handle_template_double_click','handle_drop','start_drag_visuals','equip_selected','unequip_selected',
  'equip_item_to_slot','queue_for_autosell','remove_from_autosell','destroy_selected_item',
  'confirm_destroy_selected_item','confirm_destroy_junk'})do
  wrap(I,name,function(original)return function(...)
   if S.enabled and S.editing then return end
   return original(...)
  end end)
 end
 wrap(I,'on_update_event',function(original)return function(...)
  -- Defer releasing the guard until the modal is closed and held keys are up.
  -- This prevents Enter/Escape/Space from acting on an inventory item on return.
  if S.enabled and S.closing then
   local name=rawget(G,'name_win')
   if (type(name)~='table' or not name.m_inited) and N.idle('InventoryPlus')then
    S.editing=false;S.closing=false;S.callback=nil;update_hint()
    log('Search closed; inventory input restored.')
    return -- consume this update; native inventory resumes on the following one
   end
  end
  if S.enabled and S.editing then return end
  local result=pack(original(...))
  if available() and N.poll('Ctrl+F')then S.open_search()end
  return returns(result)
 end end)
 if not S.announced then S.announced=true;log('Search UI trial ready. Open inventory and press Ctrl+F. Rows and item actions are unchanged outside the dialog.')end
end
function S.detach()
 S.enabled=false
 local name=rawget(G,'name_win')
 if S.editing and type(name)=='table' and name.m_callback==S.callback and name.m_inited and type(name.cancel_name)=='function'then pcall(name.cancel_name)end
 S.editing=false;S.closing=false;S.callback=nil;restore_hint()
 for i=#S.hooks,1,-1 do local h=S.hooks[i];if h.module[h.name]==h.replacement then h.module[h.name]=h.original end end
 return true
end
S.attach();return S
end
local ok,result=pcall(bootstrap)
if not ok then
 local partial=rawget(_G,'InventoryPlusTrial')
 if type(partial)=='table'and type(partial.detach)=='function'then pcall(partial.detach)end
 print('[InventoryPlus] Adapter disabled: '..tostring(result));return false
end
return result
