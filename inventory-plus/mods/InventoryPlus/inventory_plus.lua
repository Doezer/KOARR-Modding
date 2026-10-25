-- Inventory Plus 0.3.2: native category-scoped search and grouped name sorting.
local function bootstrap()
local G=_G
local previous=rawget(G,'InventoryPlus')
if previous and previous.enabled then previous.attach();return previous end
local function log(message)print('[InventoryPlus] '..message)end
local N=rawget(G,'InventoryPlusNative')
if type(N)~='table' or type(N.self_test)~='function' or type(N.poll)~='function' or type(N.idle)~='function' or type(N.fold)~='function' or type(N.item_name)~='function' then
 log('Native inventory helper unavailable; no inventory changes installed.');return false
end
local M=rawget(G,'InventoryPlusModel')
if type(M)~='table' then log('Row model unavailable; no inventory hooks installed.');return false end
local S={enabled=true,version='0.3.2-preview',hooks={},query='',editing=false,closing=false,ready=false,order='native',matched=0,total=0}
G.InventoryPlus=S
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
 local sort=S.order=='az' and 'A-Z' or S.order=='za' and 'Z-A' or ''
 if S.query~='' then
  local text=S.matched==0 and 'No matches' or M.short(S.query,6)
  return text..' '..tostring(S.matched)..'/'..tostring(S.total)..(sort~='' and ' '..sort or '')..' | Esc: Clear'
 end
 return sort~='' and (sort..' | Ctrl+F: Find | Ctrl+S') or 'Ctrl+F: Find | Ctrl+S: Sort'
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
  and type(I.m_button_definitions)=='table' and type(I.m_button_definitions[I.m_selected_slot])=='table'
  and type(I.m_last_set)=='table'
  and type(W)=='table' and type(W.is_visible)=='function' and W.is_visible(I.m_window)
  and (I.m_curr_mode=='replace' or I.m_curr_mode=='pocket')
end
local function ensure_bridge()
 if S.ready then return true end
 local ok,reply=pcall(N.self_test,'InventoryPlus 0.3.1')
 if not ok or reply~='InventoryPlus 0.3.1'then
  if not S.bridge_warning then log('Native version mismatch; replace the complete package.');S.bridge_warning=true end
  return false
 end
 local folded,normalized=pcall(N.fold,'InVeNtOrY PlUs')
 if not folded or normalized~='inventory plus'then
  if not S.bridge_warning then log('Native text normalization failed; search/sort left disabled.');S.bridge_warning=true end
  return false
 end
 S.ready=true;return true
end
local function restore_categories()
 if S.expanded_restore then
  for state,old in pairs(S.expanded_restore)do state.collapsed=old.value end
  S.expanded_restore=nil
 end
end
local function remember_categories(I)
 S.expanded_restore=S.expanded_restore or {}
 if type(I.m_category_status)=='table' then
  for _,state in pairs(I.m_category_status)do
   if type(state)=='table' and not S.expanded_restore[state]then
    S.expanded_restore[state]={value=state.collapsed};state.collapsed=false
   end
  end
 end
end
local function active()return S.query~='' or S.order~='native'end
local function item_name(handle)
 local A=rawget(G,'ACTOR')
 assert(type(A)=='table' and type(A.is_valid)=='function','Item-name API unavailable')
 assert(A.is_valid(handle),'Stale item handle')
 return N.item_name(handle)
end
function S.refresh()
 local I=rawget(G,'inventory_win')
 if type(I)~='table' or type(I.rebuild_list_win)~='function' then return false end
 S.refreshing=true
 local ok,err=pcall(function()
  I.rebuild_list_win()
  if type(I.update_visibility)=='function'then I.update_visibility()end
  if type(I.update_rose)=='function'then I.update_rose()end
 end)
 S.refreshing=false
 if not ok then
  S.query='';S.order='native';restore_categories()
  pcall(I.rebuild_list_win)
  log('View update failed; search/sort disabled: '..tostring(err));update_hint();return false
 end
 update_hint();return true
end
function S.set_query(text)
 if type(text)~='string' or not ensure_bridge()then return false end
 text=M.trim(text)
 if text~='' then remember_categories(rawget(G,'inventory_win'))else restore_categories()end
 S.query=text
 return S.refresh()
end
function S.clear_search()
 if S.query==''then return false end
 return S.set_query('')
end
function S.cycle_sort()
 if not ensure_bridge()then return false end
 S.order=S.order=='native' and 'az' or S.order=='az' and 'za' or 'native'
 return S.refresh()
end
local function shortcuts(action)
 if not available()then return false end
 local menu=rawget(G,'menu_tools')
 if type(menu)=='table' and type(menu.is_dragging)=='function' and menu.is_dragging()then return false end
 if S.query~='' and type(action)=='string'then
  local key=string.lower(action)
  if key=='b' or key=='exiting' or key=='exitingshortcut'then S.back_guard=true;S.clear_search();return true end
 end
 if N.poll('Ctrl+F')then S.open_search();return true end
 if N.poll('Ctrl+S')then S.cycle_sort();return true end
 return false
end
function S.open_search()
 if not available() or S.editing or S.back_guard then return false end
 local name=rawget(G,'name_win')
 if type(name)~='table' or type(name.launch)~='function' or name.m_inited then return false end
 local tutorial=rawget(G,'tutorial_win')
 if type(tutorial)=='table' and type(tutorial.is_modal_tutorial_active)=='function' and tutorial.is_modal_tutorial_active()then return false end
 local menu=rawget(G,'menu_tools')
 if type(menu)=='table' and type(menu.is_dragging)=='function' and menu.is_dragging()then return false end
 if not ensure_bridge()then log('Keyboard bridge check failed; search disabled.');return false end
 S.editing=true;S.closing=false;S.pending_query=nil
 local callback=function(text,cancelled)
  if not S.editing or S.callback~=name.m_callback then return end
  if not cancelled and type(text)=='string' then S.pending_query=text end
  S.closing=true
  log(cancelled and 'Search cancelled.' or 'Search text accepted.')
 end
 S.callback=callback
 -- Original six-argument name_win contract; it creates/focuses the native modal.
 local ok,err=pcall(name.launch,'Search items',S.query,false,64,callback,false)
 if not ok then
  if name.m_inited and name.m_callback==callback and type(name.cancel_name)=='function' then pcall(name.cancel_name)end
  S.editing=false;S.closing=false;S.callback=nil;S.pending_query=nil
  log('Could not open search: '..tostring(err));return false
 end
 log('Native search dialog requested.');return true
end
function S.attach()
 local I=rawget(G,'inventory_win')
 if type(I)~='table' or type(I.on_update_event)~='function' or type(I.on_window_event)~='function' then return end
 -- Project fresh native row tables; never change the actor's inventory arrays.
 wrap(I,'get_surplus_inventory',function(original)return function(...)
  if S.enabled and S.view_slot~=I.m_selected_slot then S.view_slot=I.m_selected_slot;S.category_changed=true end
  if not S.enabled or not active()then return original(...)end
  if S.query~=''then remember_categories(I)end
  local changed={}
  if type(I.m_category_status)=='table'then
   for _,state in pairs(I.m_category_status)do
    if type(state)=='table'then changed[#changed+1]={state=state,value=state.collapsed};state.collapsed=false end
   end
  end
  local raw=pack(pcall(original,...))
  for _,old in ipairs(changed)do old.state.collapsed=old.value end
  if not raw[1]then error(raw[2],0)end
  local ok,view=pcall(M.project,raw[2],S.query,S.order,item_name,N.fold,I.m_category_status)
  if not ok then
   S.query='';S.order='native';restore_categories()
   log('Search/sort unavailable; showing native list: '..tostring(view))
   return original(...)
  end
  I.m_cur_categories=view.categories;S.matched=view.matched;S.total=view.total
  raw[2]=view.rows
  return unpack(raw,2,raw.n)
 end end)
 wrap(I,'get_selected_item',function(original)return function(...)
  local result=pack(original(...))
  if S.enabled and active() and result[1]~=nil and type(result[1])~='string'then
   local A=rawget(G,'ACTOR')
   if type(A)=='table' and type(A.is_valid)=='function' and not A.is_valid(result[1])then return nil end
  end
  return returns(result)
 end end)
 local function remap_selection()
  local pending=S.rebuild_selection
  if pending and not pending.applied and I.m_list and type(I.m_list.set_selected)=='function'and type(I.m_last_set)=='table'then
   pending.applied=true
   local index=M.selection(I.m_last_set,pending.handle,pending.index)
   if index~=nil then I.m_list:set_selected(index)end
   I.m_mouse_event_received=false;I.m_moused_over_id=nil
  end
 end
 wrap(I,'update_selected_window',function(original)return function(...)
  -- Native rebuild calls this before returning. Select by handle before any
  -- tooltip/card observer can see the item now occupying the old row index.
  if S.enabled then remap_selection()end
  return original(...)
 end end)
 wrap(I,'rebuild_list_win',function(original)return function(...)
  local preserve=S.enabled and (active() or S.refreshing) and S.view_slot==I.m_selected_slot and not S.category_changed
  local pending=preserve and {} or nil
  if pending and I.m_list and type(I.m_list.get_selected)=='function' and type(I.get_selected_item)=='function'then
   pending.index=I.m_list:get_selected();pending.handle=I.get_selected_item()
  end
  local old=S.rebuild_selection;S.rebuild_selection=pending
  local result=pack(pcall(original,...))
  if result[1] and pending and not pending.applied then
   local ok,err=pcall(function()
    remap_selection()
    if type(I.update_selected_window)=='function'then I.update_selected_window(I.m_selected_item_window)end
   end)
   if not ok then result={n=2,false,err}end
  end
  S.rebuild_selection=old
  if not result[1]then error(result[2],0)end
  S.category_changed=false
  update_hint();return unpack(result,2,result.n)
 end end)
 wrap(rawget(G,'ledger_win'),'set_reminder',function(original)return function(...)
  local W=rawget(G,'WINDOW')
  local browsing=not S.window_hidden and available() and I.m_list_wrapper
   and W.is_visible(I.m_list_wrapper)
  if S.enabled and not S.window_hidden and (scope or browsing) then return capture(original,...)end
  reminder=nil;return original(...)
 end end)
 wrap(I,'button_tree_callback',function(original)return function(...)
  local old=scope;scope=S.enabled
  local result=pack(pcall(original,...));scope=old
  if not result[1]then error(result[2],0)end
  return unpack(result,2,result.n)
 end end)
 wrap(I,'on_window_event',function(original)return function(event,...)
  if event=='SHOW'then S.window_hidden=false end
  if S.enabled and (event=='HIDE' or event=='START_CLOSE')then
   S.window_hidden=true
   restore_hint();if not S.editing then S.query='';restore_categories()end
  end
  if S.enabled and event=='SHOW' and not S.editing then S.query='';restore_categories()end
  if S.enabled and event=='SHOW' then N.poll('Ctrl+F');N.poll('Ctrl+S')end
  return original(event,...)
 end end)
 -- Block the ledger's action dispatch before it reaches the native button tree.
 -- name_win's own modal handlers stay active for text, confirmation and cancel.
 wrap(rawget(G,'ledger_win'),'on_inputdeviceaction_event',function(original)return function(window,action,...)
  if S.enabled and (S.editing or S.back_guard)then return end
  if shortcuts(action)then return end
  return original(window,action,...)
 end end)
 wrap(I,'handle_input',function(original)return function(input,...)
  if not S.editing and not S.back_guard and shortcuts(type(input)=='table' and input.info)then
   if type(input)=='table'then input.handled=true end;return
  end
  if S.enabled and (S.editing or S.back_guard)then if type(input)=='table'then input.handled=true end;return end
  return original(input,...)
 end end)
 for _,name in ipairs({'on_button_event_selection','on_mouse_event_scroll','on_mouse_event_tooltip',
  'handle_template_double_click','handle_drop','start_drag_visuals','equip_selected','unequip_selected',
  'equip_item_to_slot','queue_for_autosell','remove_from_autosell','destroy_selected_item',
  'confirm_destroy_selected_item','confirm_destroy_junk'})do
  local action_name=name
  wrap(I,name,function(original)return function(...)
   if S.enabled and (S.editing or S.back_guard)then return end
   if S.enabled and S.query~='' and action_name=='confirm_destroy_junk'then
    log('Clear search before destroying all junk.');return
   end
   if S.enabled and active() and (action_name=='equip_selected' or action_name=='unequip_selected' or action_name=='destroy_selected_item')
    and type(I.get_selected_item)=='function' and I.get_selected_item()==nil then return end
   return original(...)
  end end)
 end
 wrap(I,'on_update_event',function(original)return function(...)
  if S.enabled and S.back_guard then
   if N.idle('InventoryPlus')then S.back_guard=false end
   return
  end
  -- Defer releasing the guard until the modal is closed and held keys are up.
  -- This prevents Enter/Escape/Space from acting on an inventory item on return.
  if S.enabled and S.closing then
   local name=rawget(G,'name_win')
   if (type(name)~='table' or not name.m_inited) and N.idle('InventoryPlus')then
    S.editing=false;S.closing=false;S.callback=nil
    local query=S.pending_query;S.pending_query=nil
    if query~=nil then S.set_query(query)else update_hint()end
    log('Search closed; '..tostring(S.matched)..'/'..tostring(S.total)..' matching items.')
    return -- consume this update; native inventory resumes on the following one
   end
  end
  if S.enabled and S.editing then return end
  local result=pack(original(...))
  shortcuts()
  local W=rawget(G,'WINDOW')
  if not S.window_hidden and available() and I.m_list_wrapper and W.is_visible(I.m_list_wrapper)then update_hint()end
  return returns(result)
 end end)
 if not S.announced then S.announced=true;log('Search preview ready. Ctrl+F: find; Ctrl+S: name sort; Esc: clear search.')end
end
function S.detach()
 S.enabled=false
 local name=rawget(G,'name_win')
 if S.editing and type(name)=='table' and name.m_callback==S.callback and name.m_inited and type(name.cancel_name)=='function'then pcall(name.cancel_name)end
 S.editing=false;S.closing=false;S.back_guard=false;S.callback=nil;S.pending_query=nil;S.query='';S.order='native';restore_categories();restore_hint()
 local I=rawget(G,'inventory_win')
 if type(I)=='table'and I.m_inited and I.m_list and type(I.rebuild_list_win)=='function'then pcall(I.rebuild_list_win)end
 for i=#S.hooks,1,-1 do local h=S.hooks[i];if h.module[h.name]==h.replacement then h.module[h.name]=h.original end end
 return true
end
S.attach();return S
end
local ok,result=pcall(bootstrap)
if not ok then
 local partial=rawget(_G,'InventoryPlus')
 if type(partial)=='table'and type(partial.detach)=='function'then pcall(partial.detach)end
 print('[InventoryPlus] Adapter disabled: '..tostring(result));return false
end
return result
