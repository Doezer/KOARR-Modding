local M=dofile('mods/InventoryPlus/navigation.lua')
local made=0
local root={id_string=1,children={}}
local inventory={id_string=4242793,parent=root,children={}}
root.children={inventory}
local weapons={id_string=2468509,parent=inventory,children={}}
inventory.children={weapons}
for _,id in ipairs({2627341,2010694})do weapons.children[#weapons.children+1]={id_string=id,parent=weapons,children={}}end
for _,id in ipairs({1070770,6689260,7304644,911336,607556})do inventory.children[#inventory.children+1]={id_string=id,parent=inventory,children={}}end
local tree={m_tree=root,m_path={4242793,2468509}}
function tree:find_node(id)
 local function find(n)if n.id_string==id then return n end;for _,c in ipairs(n.children)do local v=find(c);if v then return v end end end
 return find(root)
end
function tree:get_cur_node()local n=root;for _,id in ipairs(self.m_path)do for _,c in ipairs(n.children)do if c.id_string==id then n=c;break end end end;return n end
local up,down=0,0
function tree:go_up_a_level()up=up+1;table.remove(self.m_path);inventory_win.m_list_wrapper.visible=false end
function tree:set_highlight(i)self.index=i end
function tree:go_down_a_level()
 down=down+1
 local node=self:get_cur_node().children[self.index]
 if #node.children>0 then self.m_path[#self.m_path+1]=node.id_string
 else self.m_node_load_in_progress=true;self.loading=node end
end
local I={m_inited=true,m_window={},m_list_wrapper={visible=true},m_curr_mode='replace',m_selected_slot=2627341,
 m_button_definitions={[2627341]={},[1070770]={}}}
inventory_win=I;ledger_win={m_button_tree=tree,launch_into_button=function()error('No direct leaf jump')end}
WINDOW={is_visible=function(w)return w.visible~=false end,create_window=function()made=made+1;error('Skip visual construction in traversal test')end,
 destroy_window=function()end,get_left=function()return 0 end,get_top=function()return 0 end,get_width=function()return 360 end,get_height=function()return 500 end,
 resize=function()end,move=function()end,set_label_text=function()end,set_visible=function()end,find_static_type=function()end,get_parent_ui_win=function()end}
UIXML_ID=function()return 1 end
local idle=false;local S={enabled=true,query='frost',order='za',set_query=function(q)S.query=q end}
local T=M.create(S,function()end,{idle=function()return idle end});T.failed=true
assert(T.select(3)and S.navigating)
T.update();assert(up==0 and down==0) -- queued until mouse/shortcut is released
idle=true;T.update();assert(up==1 and down==0)
T.update();assert(down==1 and tree.m_node_load_in_progress)
T.update();assert(down==1) -- never repeat while native load callback is pending
I.m_selected_slot=1070770;I.m_list_wrapper.visible=true;tree.m_node_load_in_progress=false
T.update();assert(not S.navigating and S.query=='frost'and S.order=='za')
assert(T.select(1));T.cancel();T.update();assert(not S.navigating and down==1)
-- A tab press owns retargeted releases even if its windows disappear.
local button={};T.windows={{root=button,label={}}}
assert(T.event('DOWN',button)and T.owns_click())
assert(T.event('UP',{})and T.owns_click()) -- unrelated underlying native button
T.close();assert(T.owns_click()) -- window lifetime does not end click ownership
idle=false;T.update();assert(T.owns_click())
idle=true;T.update();assert(T.owns_click())
T.update();assert(not T.owns_click())
T.cancel()
-- The native event argument order is unconfirmed; either order is owned.
T.windows={{root=button,label={}}}
assert(T.event(button,'DOWN')and T.owns_click())
T.click_owned=false;T.windows={};T.cancel() -- the DOWN also queued a navigation
-- Primary and Secondary are separate native contexts, not aliases.
I.m_selected_slot=2627341;I.m_list_wrapper.visible=true
I.m_button_definitions[2010694]={}
tree.m_path={4242793,2468509};tree.m_node_load_in_progress=false
assert(T.select(2));T.update()
assert(tree.loading.id_string==2010694)
I.m_selected_slot=2010694;tree.m_node_load_in_progress=false;T.update()
assert(not S.navigating)
-- Entering Inventory bypasses the old category landing page even if the
-- previous selected slot is stale and already equals the entry destination.
T.last_index=1;tree.m_path={4242793};I.m_selected_slot=2627341;I.m_list_wrapper.visible=false
tree.m_window={visible=true};tree.m_is_enabled=true
function tree:remove_tree_focus()self.m_is_enabled=false end
function tree:show()self.m_window.visible=true;self.m_is_enabled=true end
WINDOW.set_visible=function(w,v)w.visible=v end
T.update();assert(S.navigating and not tree.m_window.visible)
T.update();assert(tree.loading.id_string==2627341)
I.m_list_wrapper.visible=true;tree.m_node_load_in_progress=false;T.update()
assert(not S.navigating)
assert(T.back())
for _=1,4 do T.update()end
assert(not S.navigating and #tree.m_path==0 and tree.m_window.visible)
-- Other ledger sections retain the original navigation window.
tree.m_window.visible=true;T.update();assert(tree.m_window.visible)
-- Sort and Find buttons: the click is owned, the action runs once after the release, Back cancels it.
do
 local sorted,found=0,0
 S.cycle_sort=function()sorted=sorted+1 end;S.open_search=function()found=found+1 end
 local sort_btn,find_btn={},{}
 local saved_windows=T.windows
 local function buttons()T.windows={{root=sort_btn,label={},action='sort'},{root=find_btn,label={},action='find'}}end
 -- A visible, categorised inventory list keeps T.update from closing the controls.
 I.m_list_wrapper.visible=true;I.m_window.visible=true;I.m_selected_slot=2627341
 idle=true;T.click_owned=false;T.queued=nil;buttons()
 assert(T.event('DOWN',sort_btn) and T.owns_click() and sorted==0)
 assert(T.event('UP',{}) and sorted==0)
 for _=1,4 do T.update()end
 assert(sorted==1 and found==0 and not T.owns_click())
 buttons();for _=1,3 do T.update()end;assert(sorted==1) -- never repeats
 buttons();assert(T.event('DOWN',find_btn));T.cancel() -- Back cancels the queued action
 for _=1,4 do T.update()end
 assert(found==0)
 buttons();T.click_owned=false;assert(T.event('DOWN',find_btn))
 for _=1,4 do T.update()end;assert(found==1)
 T.windows=saved_windows;T.click_owned=false;T.cancel();S.cycle_sort=nil;S.open_search=nil
end
-- Chained key chords: keys stay held (never idle), the newest press retargets, no timeout.
idle=false;T.cancel();T.exiting=nil;tree.m_node_load_in_progress=false;tree.m_path={4242793,2468509}
I.m_selected_slot=2627341;I.m_list_wrapper.visible=true
assert(T.select(3,true) and S.navigating)
assert(T.select(2,true) and T.pending.id==2010694 and T.pending.key) -- retargeted while moving
T.update();assert(tree.loading and tree.loading.id_string==2010694) -- advanced without a key release
assert(not T.select(2,false)) -- a pointer press during a move is still refused
T.cancel();tree.loading=nil;tree.m_node_load_in_progress=false;idle=true
-- Regression: the Weapons subtree has no parent links in the game. The route comes from
-- `children`, and being inside Inventory comes from the native path, never from `parent`.
local saved_parent=weapons.parent
weapons.parent=nil;for _,c in ipairs(weapons.children)do c.parent=nil end
I.m_selected_slot=1070770;I.m_list_wrapper.visible=true;tree.m_path={4242793,1070770};tree.m_node_load_in_progress=false
assert(T.select(1) and S.navigating and T.pending.route[1]==4242793 and T.pending.route[3]==2627341)
T.cancel()
weapons.parent=saved_parent;for _,c in ipairs(weapons.children)do c.parent=weapons end
-- A non-Back exit (a ledger shortcut jump) must not strand the hidden tree.
tree.m_path={4242793};I.m_list_wrapper.visible=true;I.m_selected_slot=2627341
T.update();assert(not tree.m_window.visible)
tree.m_path={};T.update();assert(tree.m_window.visible)
-- If no category can be entered, restore the native menu instead of a blank page.
local all={}
for _,c in ipairs(inventory.children)do all[#all+1]=c end
for _,c in ipairs(weapons.children)do all[#all+1]=c end
for _,c in ipairs(all)do c.disabled=true end
tree.m_path={4242793};I.m_list_wrapper.visible=false;tree.m_window.visible=true;tree.m_is_enabled=true
local before=down
T.update();assert(tree.m_window.visible and not S.navigating and T.native_menu)
for _=1,5 do T.update()end
assert(down==before and tree.m_window.visible) -- no retry loop
tree.m_path={};T.update();assert(not T.native_menu)
for _,c in ipairs(all)do c.disabled=nil end
tree.m_path={4242793,2468509}
-- Visible inventory root and a stale selected slot are not enough to show tabs.
I.m_list_wrapper.visible=false;T.failed=false;T.update();assert(made==0)
I.m_list_wrapper.visible=true;T.update();assert(made==1 and T.failed)
-- The list's scrolling content window keeps the full-height viewport's range: pad it by the
-- reserved height (again after each native rebuild) and restore it when the controls go away.
do
 local resized={}
 local content_h=3675
 local real_resize,real_height=WINDOW.resize,WINDOW.get_height
 WINDOW.resize=function(w,width,height)resized[#resized+1]={w=w,h=height};if w==io.stdout then content_h=height end end
 WINDOW.get_height=function(w)if w==io.stdout then return content_h end;return 500 end
 WINDOW.create_window=function()return {} end
 WINDOW.find_static_type=function()return {} end
 local content=io.stdout -- any userdata stands in for a window handle
 I.m_list={window=content,selected=3}
 T.failed=false;T.windows={};T.geometry=nil;T.list_content=nil
 I.m_selected_slot=2627341;I.m_list_wrapper.visible=true;tree.m_path={4242793,2468509}
 T.update()
 assert(content_h==3675+96) -- padded by the 96 reserved for the tab and button rows
 resized={};T.update();assert(#resized==0) -- unchanged: not padded again
 content_h=3675;T.update();assert(content_h==3675+96) -- the native rebuild reset it: padded again
 T.close();assert(content_h==3675 and T.list_content==nil) -- restored
 WINDOW.resize,WINDOW.get_height=real_resize,real_height
end
print('Navigation: common-parent traversal, async load, release gate, cancellation and landing-page gating passed')
