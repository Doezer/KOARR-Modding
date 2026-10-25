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
 local function blocked()
  local name,tutorial,menu=rawget(_G,'name_win'),rawget(_G,'tutorial_win'),rawget(_G,'menu_tools')
  return not S.enabled or S.editing or S.back_guard or S.navigating
   or (name and name.m_inited)
   or (tutorial and type(tutorial.is_modal_tutorial_active)=='function' and tutorial.is_modal_tutorial_active())
   or (menu and type(menu.is_dragging)=='function' and menu.is_dragging())
 end
 function T.close()
  local _,W=context()
  for i=#T.windows,1,-1 do pcall(W.destroy_window,T.windows[i].root)end
  T.windows={}
  if T.geometry then
   local g=T.geometry;T.geometry=nil
   pcall(W.move,g.window,g.x,g.y);pcall(W.resize,g.window,g.width,g.height)
  end
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
 local function select_category(index,entry)
  local d=definitions[index];local tree,I,W=tree_context()
  if not d or blocked() or not tree or not I.m_list_wrapper or (not entry and not W.is_visible(I.m_list_wrapper))then return false end
  local node=tree:find_node(d.id)
  if not node or node.disabled then return false end
  if I.m_selected_slot==d.id and W.is_visible(I.m_list_wrapper)then return true end
  local route={};local cursor=node
  for _=1,12 do
   if not cursor or not cursor.parent then break end
   if cursor.disabled then return false end
   table.insert(route,1,cursor.id_string);cursor=cursor.parent
  end
  if cursor~=tree.m_tree then return false end
  T.pending={id=d.id,query=S.query,route=route,frames=0,tree=tree}
  S.navigating=true;return true
 end
 function T.select(index)return select_category(index,false)end
 local function in_inventory(node)
  for _=1,12 do
   if not node then return false end
   if node.id_string==4242793 then return true end
   node=node.parent
  end
  return false
 end
 function T.back()
  local tree=tree_context()
  if S.editing or S.back_guard or not tree or not in_inventory(tree:get_cur_node())then return false end
  T.cancel();T.click_owned=false;T.exiting={tree=tree,frames=0};S.navigating=true;return true
 end
 local function inventory_shell()
  local tree,I,W=tree_context();if not tree then return end
  if T.exiting then
   local p=T.exiting;p.frames=p.frames+1
   if tree~=p.tree or p.frames>180 then T.exiting=nil;S.navigating=false;return end
   if tree.m_node_load_in_progress or not N.idle('InventoryPlus')then return end
   if in_inventory(tree:get_cur_node())then tree:go_up_a_level()
   else
    T.exiting=nil;S.navigating=false;T.close()
    if type(tree.show)=='function'then tree:show()end
   end
   return
  end
  local node=tree:get_cur_node()
  if not in_inventory(node)then return end
  -- Hide only the ledger category tree, never the native inventory contents.
  if tree.m_window then
   if type(tree.remove_tree_focus)=='function'and tree.m_is_enabled then tree:remove_tree_focus()end
   W.set_visible(tree.m_window,false)
  end
  if not T.pending and not blocked() and I.m_inited and not W.is_visible(I.m_list_wrapper)
   and (node.id_string==4242793 or node.id_string==2468509)then
   select_category(T.last_index or 1,true)
  end
 end
 local function advance()
  local p=T.pending;if not p then return end
  local tree,I,W=tree_context()
  if tree~=p.tree or not S.enabled then T.cancel();return end
  p.frames=p.frames+1
  if p.frames>180 then T.cancel();log('Category navigation stopped; Back remains available.');return end
  if tree.m_node_load_in_progress or not N.idle('InventoryPlus')then return end
  if I.m_selected_slot==p.id and I.m_list_wrapper and W.is_visible(I.m_list_wrapper)then
   T.cancel();if S.query~=p.query then S.set_query(p.query)end;return
  end
  local path=tree.m_path;if type(path)~='table'then T.cancel();return end
  local signature=table.concat(path,':')..':'..tostring(I.m_selected_slot)
  if p.last==signature then return end
  p.last=signature
  local common=0
  while common<#path and common<#p.route and path[common+1]==p.route[common+1]do common=common+1 end
  if #path>common then tree:go_up_a_level();return end
  local current=tree:get_cur_node();local next_id=p.route[common+1]
  for index,node in ipairs(current.children or {})do
   if node.id_string==next_id and not node.disabled then
    tree:set_highlight(index);tree:go_down_a_level();return
   end
  end
  T.cancel();log('Category unavailable in the native tree.')
 end
 function T.owns_click()return T.click_owned==true end
 function T.event(event,window)
  if T.click_owned then return true end
  local _,W=context()
  local cursor=window
  for _=1,5 do
   if not cursor then break end
   for index,tab in ipairs(T.windows)do
    if cursor==tab.root or cursor==tab.label then
     if event=='DOWN'then T.click_owned=true;T.release_ticks=0;T.select(index)end
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
   end)
   if not ok then T.close();T.failed=true;log('Category tabs unavailable; native navigation retained: '..tostring(err));return end
  end
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
 function T.detach() T.click_owned=false;T.release_ticks=0;T.cancel();T.close()end
 return T
end
return M
