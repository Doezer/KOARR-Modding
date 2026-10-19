local N=dofile('mods/InventoryPlus/navigation.lua')
local created,destroyed,actions,labels,logs=0,0,{},0,{}
local function window(parent,x,y,w,h)return {parent=parent,x=x or 0,y=y or 0,w=w or 360,h=h or 500,visible=true}end
local root=window(nil,0,0,1024,768)
local panel=window(root,20,100,360,500)
local I={m_inited=true,m_window=root,m_list_wrapper=panel,m_curr_mode='replace',m_selected_slot=2627341}
inventory_win=I
WINDOW={get_left=function(w)return w.x end,get_top=function(w)return w.y end,
 get_width=function(w)return w.w end,get_height=function(w)return w.h end,
 get_parent_ui_win=function(w)return w.parent end,is_visible=function(w)return w.visible end,
 move=function(w,x,y)w.x=x;w.y=y end,resize=function(w,x,y)w.w=x;w.h=y end,
 create_window=function(xml,template,parent)
  assert(xml=='inventory_win' and template=='INVENTORY_HEADER' and parent==I.m_window)
  created=created+1;local w=window(parent);w.button=window(w);w.label=window(w.button);return w
 end,
 find_static_type=function(w,t,id,index,recursive)
  assert(t==1221325 and id==679773 and index==-1 and recursive);return w.label
 end,
 set_label_text=function(w,s)w.text=s;labels=labels+1 end,
 set_visible=function(w,v)w.visible=v end,
 destroy_window=function(w)assert(not w.destroyed);w.destroyed=true;destroyed=destroyed+1 end}
UIXML_ID=function(s)return s end
local nodes={id_string=4242793,children={}}
for _,d in ipairs({2627341,1070770,6689260,7304644,911336,607556,2010694,2468509})do
 nodes.children[#nodes.children+1]={id_string=d,children={}}
end
I.get_button_tree_info=function()return nodes end
local S={enabled=true,query='frost',order='za'}
S.set_query=function(q)S.query=q end
local T=N.create(S,function(s)logs[#logs+1]=s end)
ledger_win={launch_into_button=function(id)
 assert(S.switching);actions[#actions+1]=id
 T.close() -- simulate native inventory HIDE/SHOW and new row context
 I.m_selected_slot=id;I.action_context=id
end}
T.update()
assert(created==6 and #T.windows==6 and panel.y==196 and panel.h==404)
assert(T.windows[1].label.text=='[1 Weapons]' and T.windows[6].label.text=='6 Junk')
local writes=labels;T.update();assert(labels==writes) -- no repeated label writes every frame
local unrelated=window(root);assert(not T.event('DOWN',unrelated))
assert(T.event('ENTER',T.windows[2].label)and #actions==0)
assert(T.event('DOWN',T.windows[2].label))
assert(I.m_selected_slot==1070770 and I.action_context==1070770 and S.query=='frost'and S.order=='za')
assert(created==12 and destroyed==6 and panel.y==196 and panel.h==404)
assert(T.windows[2].label.text=='[2 Armor]')
assert(T.event('UP',T.windows[2].label)and #actions==1)
S.editing=true;assert(not T.select(3));S.editing=false
S.back_guard=true;assert(not T.select(3));S.back_guard=false
name_win={m_inited=true};assert(not T.select(3));name_win.m_inited=false
menu_tools={is_dragging=function()return true end};assert(not T.select(3));menu_tools=nil
tutorial_win={is_modal_tutorial_active=function()return true end};assert(not T.select(3));tutorial_win=nil
nodes.children[3].disabled=true;assert(not T.select(3));nodes.children[3].disabled=false
nodes.disabled=true;assert(not T.select(3));nodes.disabled=false
assert(not T.select(0)and not T.select(7))
assert(T.select(2)and #actions==1) -- active tab does not rebuild items
I.m_selected_slot=2010694;T.update();assert(T.windows[1].label.text=='[1 Weapons]')
assert(T.select(1)and #actions==1) -- native secondary weapon context remains valid
I.m_curr_mode='compare';T.update();assert(#T.windows==0 and panel.y==100 and panel.h==500)
assert(not T.select(3))
I.m_curr_mode='replace';T.update();assert(#T.windows==6 and panel.y==196)
ledger_win.launch_into_button=function()error('Native transition failed')end
assert(not T.select(3)and not S.switching and S.query=='frost'and #logs==1)
-- Animated native transitions may finish on a later update.
ledger_win.launch_into_button=function(id)actions[#actions+1]=id end
assert(T.select(3)and S.switching)
assert(not T.select(4));I.m_selected_slot=6689260;T.update()
assert(not S.switching and T.windows[3].label.text=='[3 Accessories]')
assert(T.select(4)and S.switching)
for _=1,181 do T.update()end
assert(not S.switching and #logs==2)
T.detach();T.close();assert(panel.y==100 and panel.h==500 and created==destroyed)
-- Partial creation rolls back every owned control and the native layout.
local old=WINDOW.find_static_type
WINDOW.find_static_type=function()return nil end
T=N.create(S,function(s)logs[#logs+1]=s end);T.update()
assert(T.failed and #T.windows==0 and created==destroyed and panel.y==100 and panel.h==500)
WINDOW.find_static_type=old
T.update();assert(created==destroyed) -- failure is bounded; native inventory remains usable
print('Inventory tabs: native routing, modal guards, hit ownership, layout restoration and creation rollback passed')
