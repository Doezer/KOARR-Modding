-- Native category tabs. Own only cloned headers and the list wrapper's geometry.
if _G.InventoryPlusNavigationV2 then return _G.InventoryPlusNavigationV2 end
local M={}
_G.InventoryPlusNavigationV2=M
local definitions={
 {id=2627341,parent=2468509,title='Primary'},
 {id=2010694,parent=2468509,title='Secondary'},
 {id=1070770,title='Armor'},{id=6689260,title='Accessories'},
 {id=7304644,title='Consumables'},{id=911336,title='Items'},{id=607556,title='Junk'}
}
function M.create(S,log,N)
 local T={windows={},definitions=definitions}
 local function context()
  return rawget(_G,'inventory_win'),rawget(_G,'WINDOW'),rawget(_G,'ledger_win')
 end
 -- Bounded diagnostics: a silent refusal is indistinguishable from a dead button.
 local notes=0
 local function note(message)
  if notes<60 then notes=notes+1;log('[nav] '..message)end
 end
 -- A keyboard chord may retarget a move that is still under way (latest press wins).
 local function blocked(retarget)
  local name,tutorial,menu=rawget(_G,'name_win'),rawget(_G,'tutorial_win'),rawget(_G,'menu_tools')
  local moving=S.navigating and not (retarget and T.pending and not T.exiting)
  return not S.enabled or S.editing or S.back_guard or moving
   or (name and name.m_inited)
   or (tutorial and type(tutorial.is_modal_tutorial_active)=='function' and tutorial.is_modal_tutorial_active())
   or (menu and type(menu.is_dragging)=='function' and menu.is_dragging())
 end
function T.pad_list()
  local _,W=context()
  local c=T.list_content;if not c then return end
  local okh,h=pcall(W.get_height,c.window);local okw,w=pcall(W.get_width,c.window)
  if not(okh and okw and type(h)=='number')then return end
  if h==c.padded then return end -- unchanged since our last padding
  c.width=w
  if h>c.viewport then
   c.original=h;c.padded=h+c.reserve
   pcall(W.resize,c.window,w,c.padded)
   note('padded list content '..tostring(h)..' -> '..tostring(c.padded))
  else c.original=nil;c.padded=h end
 end
 function T.close()
  local _,W=context()
  for i=#T.windows,1,-1 do pcall(W.destroy_window,T.windows[i].root)end
  T.windows={}
  if T.geometry then
   local g=T.geometry;T.geometry=nil
   pcall(W.move,g.window,g.x,g.y);pcall(W.resize,g.window,g.width,g.height)
  end
  local c=T.list_content;T.list_content=nil
  if c and c.original and c.padded and c.padded~=c.original then pcall(W.resize,c.window,c.width,c.original)end
  T.parent=nil;T.last_slot=nil;T.last_visible=nil;T.last_mode=nil
 end
 function T.cancel()
  T.pending=nil;T.exiting=nil;S.navigating=false
 end
 local function tree_context()
  local I,W,L=context();local tree=L and L.m_button_tree
  if type(tree)~='table'then return end
  for _,name in ipairs({'find_node','get_cur_node','set_highlight','go_down_a_level','go_up_a_level'})do
   if type(tree[name])~='function'then return end
  end
  return tree,I,W
 end
 local function find_route(tree,id)
  local function walk(node,trail,depth)
   if depth>8 or type(node)~='table' then return end
   for _,child in ipairs(node.children or {})do
    trail[#trail+1]=child
    if child.id_string==id then return trail end
    local found=walk(child,trail,depth+1);if found then return found end
    trail[#trail]=nil
   end
  end
  return walk(tree.m_tree,{},1)
 end
 local function busy_reason(retarget)
  local name,tutorial,menu=rawget(_G,'name_win'),rawget(_G,'tutorial_win'),rawget(_G,'menu_tools')
  if not S.enabled then return 'disabled' end
  if S.editing then return 'editing' end
  if S.back_guard then return 'back guard' end
  if S.navigating and not (retarget and T.pending and not T.exiting)then return 'already navigating' end
  if name and name.m_inited then return 'text dialog open' end
  if tutorial and type(tutorial.is_modal_tutorial_active)=='function' and tutorial.is_modal_tutorial_active()then return 'tutorial' end
  if menu and type(menu.is_dragging)=='function' and menu.is_dragging()then return 'dragging' end
 end
 local function select_category(index,entry,from_key)
  local d=definitions[index];local tree,I,W=tree_context()
  local function refuse(reason)note('tab '..tostring(index)..' refused: '..reason);return false end
  if not d then return false end
  if blocked(from_key) then return refuse('busy ('..tostring(busy_reason(from_key))..')')end
  if not tree then return refuse('ledger tree unavailable')end
  if not I.m_list_wrapper then return refuse('no item list')end
  if not entry and not W.is_visible(I.m_list_wrapper)then return refuse('item list hidden')end
  -- Build the route from the root through `children`, as find_node does: `parent` links are
  -- not reliable (the Weapons subtree has none), so they must not decide the route.
  local trail=find_route(tree,d.id)
  if not trail then return refuse('node '..tostring(d.id)..' not found in tree')end
  if I.m_selected_slot==d.id and W.is_visible(I.m_list_wrapper)then return true end
  local route={}
  for _,step in ipairs(trail)do
   if step.disabled then return refuse('node '..tostring(step.id_string)..' disabled')end
   route[#route+1]=step.id_string
  end
  note('tab '..tostring(index)..' route '..table.concat(route,'>')..' from path '..table.concat(tree.m_path or {},'>'))
  -- Key-initiated moves need no key-release wait: the chord guard already swallows the game's
  -- own key events. Pointer moves keep waiting for the button to come up.
  T.pending={id=d.id,query=S.query,route=route,frames=0,tree=tree,key=from_key==true}
  S.navigating=true;return true
 end
 function T.select(index,from_key)return select_category(index,false,from_key)end
 -- The native path holds ids from the root; parent links are not reliable for every node.
 local function in_inventory(tree)
  local path=tree.m_path
  return type(path)=='table' and path[1]==4242793
 end
 function T.back()
  local tree=tree_context()
  if S.editing or S.back_guard or not tree or not in_inventory(tree)then return false end
  T.cancel();T.click_owned=false;T.exiting={tree=tree,frames=0};S.navigating=true;return true
 end
 -- Give the native category menu back instead of leaving a blank hidden page.
 local function fall_back(tree,message)
  T.native_menu=true;T.hidden_tree=nil
  if type(tree.show)=='function'then tree:show()end
  log(message)
 end
 local function inventory_shell()
  local tree,I,W=tree_context();if not tree then return end
  if T.exiting then
   local p=T.exiting;p.frames=p.frames+1
   if tree~=p.tree or p.frames>180 then T.exiting=nil;S.navigating=false;return end
   if tree.m_node_load_in_progress or not N.idle('InventoryPlus')then return end
   if in_inventory(tree)then tree:go_up_a_level()
   else
    T.exiting=nil;S.navigating=false;T.close();T.hidden_tree=nil
    if type(tree.show)=='function'then tree:show()end
   end
   return
  end
  local node=tree:get_cur_node()
  if not in_inventory(tree)then
   -- Any exit (Back, a ledger shortcut jump) must give the tree back if we hid it.
   T.native_menu=false
   if T.hidden_tree then
    T.hidden_tree=nil
    if type(tree.show)=='function'then tree:show()end
   end
   return
  end
  local listed=I.m_list_wrapper and W.is_visible(I.m_list_wrapper)
  if T.native_menu then
   -- Entry failed earlier: keep the native category menu until a list shows or we leave.
   if listed then T.native_menu=false end
   return
  end
  -- Hide only the ledger category tree, never the native inventory contents.
  if tree.m_window then
   if type(tree.remove_tree_focus)=='function'and tree.m_is_enabled then tree:remove_tree_focus()end
   W.set_visible(tree.m_window,false);T.hidden_tree=tree
  end
  if not T.pending and not blocked() and I.m_inited and I.m_list_wrapper and not listed
   and (node.id_string==4242793 or node.id_string==2468509)then
   -- Prefer the last viewed category, then any other the native tree allows.
   local first=T.last_index or 1
   local entered=select_category(first,true)
   for index=1,#definitions do
    if entered then break end
    if index~=first then entered=select_category(index,true)end
   end
   if not entered then fall_back(tree,'No category can be entered; native category menu restored.')end
  end
 end
 local function advance()
  local p=T.pending;if not p then return end
  local tree,I,W=tree_context()
  if tree~=p.tree or not S.enabled then T.cancel();return end
  p.frames=p.frames+1
  if p.frames>180 then
   T.cancel();log('Category navigation stopped; Back remains available.')
   if not (I.m_list_wrapper and W.is_visible(I.m_list_wrapper))then fall_back(tree,'Native category menu restored.')end
   return
  end
  if tree.m_node_load_in_progress or (not p.key and not N.idle('InventoryPlus'))then return end
  if I.m_selected_slot==p.id and I.m_list_wrapper and W.is_visible(I.m_list_wrapper)then
   T.cancel();if S.query~=p.query then S.set_query(p.query)end;return
  end
  local path=tree.m_path;if type(path)~='table'then T.cancel();return end
  local signature=table.concat(path,':')..':'..tostring(I.m_selected_slot)
  if p.last==signature then return end
  p.last=signature
  note('step path='..table.concat(path,'>')..' slot='..tostring(I.m_selected_slot)..' loading='..tostring(tree.m_node_load_in_progress))
  local common=0
  while common<#path and common<#p.route and path[common+1]==p.route[common+1]do common=common+1 end
  if #path>common then note('up');tree:go_up_a_level();return end
  local current=tree:get_cur_node();local next_id=p.route[common+1]
  for index,node in ipairs(current.children or {})do
   if node.id_string==next_id and not node.disabled then
    note('down to '..tostring(next_id)..' (child '..index..')');tree:set_highlight(index);tree:go_down_a_level();return
   end
  end
  T.cancel();log('Category unavailable in the native tree (wanted '..tostring(next_id)..' under '..tostring(current.id_string)..').')
  if not (I.m_list_wrapper and W.is_visible(I.m_list_wrapper))then fall_back(tree,'Native category menu restored.')end
 end
 function T.owns_click()return T.click_owned==true end
 local seen_events,seen_count={},0
 function T.event(event,window)
  -- The native argument order is unconfirmed; the event name is the string one.
  if type(event)~='string' and type(window)=='string' then event,window=window,event end
  -- Name each distinct event once (bounded) so the framework log settles the contract.
  if type(event)=='string' and not seen_events[event] and seen_count<8 then
   seen_events[event]=true;seen_count=seen_count+1
   log('Button event '..event..' target '..type(window))
  end
  if T.click_owned then return true end
  local _,W=context()
  local cursor=window
  for _=1,5 do
   if not cursor then break end
   for index,tab in ipairs(T.windows)do
    if cursor==tab.root or cursor==tab.label then
     if event=='DOWN'then note('click on tab '..index);T.click_owned=true;T.release_ticks=0;T.select(index)end
     return true -- consume all owned events before the native list sees them
    end
   end
   local ok,parent=pcall(W.get_parent_ui_win,cursor)
   if not ok or parent==cursor then break end
   cursor=parent
  end
  if event=='DOWN'then T.cancel()end
  return false
 end
 function T.update()
  local I,W,L=context()
  inventory_shell()
  -- Async key state can report release before the queued UP event is dispatched.
  -- Keep ownership through two ledger updates, including events retargeted to
  -- native controls, and only then start changing/destroying tab windows.
  if T.click_owned then
   if I then I.m_mouse_event_received=false;I.m_moused_over_id=nil end
   if N.idle('InventoryPlus')then T.release_ticks=T.release_ticks+1 else T.release_ticks=0 end
   if T.release_ticks>=2 then T.click_owned=false;T.release_ticks=0 end
  elseif not T.exiting then advance()end
  if not I or not I.m_inited or not I.m_window or not I.m_list_wrapper or not W then return end
  if not W.is_visible(I.m_window) or not W.is_visible(I.m_list_wrapper)
   or type(I.m_button_definitions)~='table' or not I.m_button_definitions[I.m_selected_slot]
   or (I.m_curr_mode~='replace'and I.m_curr_mode~='pocket')then
   T.close();return
  end
  if T.parent and T.parent~=I.m_window then T.close()end
  if #T.windows==0 and not T.failed then
   local ok,err=pcall(function()
    for _,name in ipairs({'create_window','find_static_type','get_parent_ui_win','get_left','get_top',
     'get_width','get_height','move','resize','destroy_window','set_label_text','set_visible'})do
     assert(type(W[name])=='function','Missing WINDOW.'..name)
    end
    assert(tree_context(),'Native category traversal unavailable')
    local x,y,width,height=W.get_left(I.m_list_wrapper),W.get_top(I.m_list_wrapper),W.get_width(I.m_list_wrapper),W.get_height(I.m_list_wrapper)
    assert(width>=320 and height>=180,'Inventory panel is too small for tabs')
    T.geometry={window=I.m_list_wrapper,x=x,y=y,width=width,height=height}
    T.parent=I.m_window
    local cell=width/2;local row_height=32;local reserved=128
    for index,d in ipairs(definitions)do
     local root=W.create_window(UIXML_ID('inventory_win'),'INVENTORY_HEADER',I.m_window)
     assert(root,'Native category header could not be created')
     local tab={root=root};T.windows[#T.windows+1]=tab
     local label=W.find_static_type(root,1221325,679773,-1,true)
     assert(label,'Native category label unavailable');tab.label=label
     W.resize(root,cell-4,row_height)
     local cursor=W.get_parent_ui_win(label)
     for _=1,3 do
      if not cursor or cursor==root or cursor==I.m_window then break end
      W.resize(cursor,cell-4,row_height);W.move(cursor,0,0);cursor=W.get_parent_ui_win(cursor)
     end
     W.resize(label,cell-12,row_height);W.move(label,4,0)
     local column=(index-1)%2;local row=(index-1-column)/2
     W.move(root,x+column*cell,y+row*row_height)
    end
    W.move(I.m_list_wrapper,x,y+reserved);W.resize(I.m_list_wrapper,width,height-reserved)
    -- The list's scrolling content window (thousands of units tall) still assumes the full-height
    -- viewport, so with the viewport shrunk the last rows sit below the reachable scroll range.
    -- pad_list() adds the reserved height to the content (and again after every native rebuild).
    T.list_content=nil
    if type(I.m_list)=='table' then
     for key,value in pairs(I.m_list)do
      if type(value)=='userdata' and not T.list_content then
       T.list_content={window=value,key=tostring(key),viewport=height-reserved,reserve=reserved}
      end
     end
     note('list content window: '..(T.list_content and T.list_content.key or 'none')..'; wrapper height '..tostring(height))
    end
   end)
   if not ok then T.close();T.failed=true;log('Category tabs unavailable; native navigation retained: '..tostring(err));return end
  end
  T.pad_list()
  local visible=W.is_visible(I.m_window) and not S.editing
  if T.last_slot==I.m_selected_slot and T.last_visible==visible and T.last_mode==I.m_curr_mode then return end
  T.last_slot=I.m_selected_slot;T.last_visible=visible;T.last_mode=I.m_curr_mode
  for index,tab in ipairs(T.windows)do
   local d=definitions[index];local selected=I.m_selected_slot==d.id
   if selected then T.last_index=index end
   local caption=tostring(index)..' '..d.title
   W.set_label_text(tab.label,selected and ('['..caption..']')or caption)
   W.set_visible(tab.root,visible)
  end
 end
 function T.detach()
  T.click_owned=false;T.release_ticks=0;T.cancel();T.close()
  local tree=T.hidden_tree;T.hidden_tree=nil;T.native_menu=false
  if tree and type(tree.show)=='function'then pcall(tree.show,tree)end
 end
 return T
end
return M
