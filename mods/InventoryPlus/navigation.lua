-- Native category tabs. Own only cloned headers and the list wrapper's geometry.
if _G.InventoryPlusNavigation then return _G.InventoryPlusNavigation end
local M={}
_G.InventoryPlusNavigation=M
local definitions={
 {id=2627341,parent=2468509,title='Weapons',also=2010694},
 {id=1070770,title='Armor'},{id=6689260,title='Accessories'},
 {id=7304644,title='Consumables'},{id=911336,title='Items'},{id=607556,title='Junk'}
}
function M.create(S,log)
 local T={windows={},definitions=definitions}
 local function context()
  return rawget(_G,'inventory_win'),rawget(_G,'WINDOW'),rawget(_G,'ledger_win')
 end
 local function blocked()
  local name,tutorial,menu=rawget(_G,'name_win'),rawget(_G,'tutorial_win'),rawget(_G,'menu_tools')
  return not S.enabled or S.editing or S.back_guard or S.switching
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
 local function nodes()
  local I,_,L=context()
  if not I or not L or type(L.launch_into_button)~='function' or type(I.get_button_tree_info)~='function'then return end
  local ok,tree=pcall(I.get_button_tree_info);if not ok then return end
  local found={}
  local function visit(node)
   if type(node)~='table'then return end
   if node.id_string~=nil then found[node.id_string]=node end
   for _,child in ipairs(node.children or {})do visit(child)end
  end
  visit(tree)
  return found
 end
 function T.select(index)
  local d=definitions[index];local I,_,L=context()
  if not d or blocked() or not I or not I.m_inited or (I.m_curr_mode~='replace'and I.m_curr_mode~='pocket')then return false end
  local found=nodes();local node=found and found[d.id];local parent=found and d.parent and found[d.parent]
  if not node or node.disabled or (parent and parent.disabled) or found[4242793] and found[4242793].disabled then return false end
  if I.m_selected_slot==d.id or I.m_selected_slot==d.also then return true end
  -- The ledger performs the full close/enter path, including action context.
  -- Never simulate a category change by assigning m_selected_slot ourselves.
  T.pending={id=d.id,query=S.query,frames=0}
  S.switching=true
  local ok,err=pcall(L.launch_into_button,d.id)
  if not ok then T.pending=nil;S.switching=false;log('Category switch failed: '..tostring(err));return false end
  T.update();return true
 end
 function T.event(event,window)
  local _,W=context()
  local cursor=window
  for _=1,5 do
   if not cursor then break end
   for index,tab in ipairs(T.windows)do
    if cursor==tab.root or cursor==tab.label then
     if event=='DOWN'then T.select(index)end
     return true -- consume all owned events before the native list sees them
    end
   end
   local ok,parent=pcall(W.get_parent_ui_win,cursor)
   if not ok or parent==cursor then break end
   cursor=parent
  end
  return false
 end
 function T.update()
  local I,W,L=context()
  if T.pending then
   local pending=T.pending
   if I and I.m_selected_slot==pending.id and I.m_inited and W.is_visible(I.m_window) then
    T.pending=nil;S.switching=false
    if S.query~=pending.query then S.set_query(pending.query)end
   else
    pending.frames=pending.frames+1
    if pending.frames>180 then
     T.pending=nil;S.switching=false;log('Category transition timed out; native navigation remains available.')
    end
    return
   end
  end
  if not I or not I.m_inited or not I.m_window or not I.m_list_wrapper or not W then return end
  if not W.is_visible(I.m_window) or (I.m_curr_mode~='replace'and I.m_curr_mode~='pocket')then
   T.close();return
  end
  if T.parent and T.parent~=I.m_window then T.close()end
  if #T.windows==0 and not T.failed then
   local ok,err=pcall(function()
    for _,name in ipairs({'create_window','find_static_type','get_parent_ui_win','get_left','get_top',
     'get_width','get_height','move','resize','destroy_window','set_label_text','set_visible'})do
     assert(type(W[name])=='function','Missing WINDOW.'..name)
    end
    local found=nodes()
    assert(L and type(L.launch_into_button)=='function' and found,'Native category navigation unavailable')
    for _,d in ipairs(definitions)do assert(found[d.id],'Native category missing: '..d.title)end
    local x,y,width,height=W.get_left(I.m_list_wrapper),W.get_top(I.m_list_wrapper),W.get_width(I.m_list_wrapper),W.get_height(I.m_list_wrapper)
    assert(width>=320 and height>=180,'Inventory panel is too small for tabs')
    T.geometry={window=I.m_list_wrapper,x=x,y=y,width=width,height=height}
    T.parent=I.m_window
    local cell=width/2;local row_height=32
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
    W.move(I.m_list_wrapper,x,y+96);W.resize(I.m_list_wrapper,width,height-96)
   end)
   if not ok then T.close();T.failed=true;log('Category tabs unavailable; native navigation retained: '..tostring(err));return end
  end
  local visible=W.is_visible(I.m_window) and not S.editing
  if T.last_slot==I.m_selected_slot and T.last_visible==visible and T.last_mode==I.m_curr_mode then return end
  T.last_slot=I.m_selected_slot;T.last_visible=visible;T.last_mode=I.m_curr_mode
  for index,tab in ipairs(T.windows)do
   local d=definitions[index];local selected=I.m_selected_slot==d.id or I.m_selected_slot==d.also
   local caption=tostring(index)..' '..d.title
   W.set_label_text(tab.label,selected and ('['..caption..']')or caption)
   W.set_visible(tab.root,visible)
  end
 end
 function T.detach()
  T.pending=nil;S.switching=false;T.close()
 end
 return T
end
return M
