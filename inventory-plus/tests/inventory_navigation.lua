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
assert(T.select(2)and S.navigating)
T.update();assert(up==0 and down==0) -- queued until mouse/shortcut is released
idle=true;T.update();assert(up==1 and down==0)
T.update();assert(down==1 and tree.m_node_load_in_progress)
T.update();assert(down==1) -- never repeat while native load callback is pending
I.m_selected_slot=1070770;I.m_list_wrapper.visible=true;tree.m_node_load_in_progress=false
T.update();assert(not S.navigating and S.query=='frost'and S.order=='za')
assert(T.select(1));T.cancel();T.update();assert(not S.navigating and down==1)
-- Visible inventory root and a stale selected slot are not enough to show tabs.
I.m_list_wrapper.visible=false;T.failed=false;T.update();assert(made==0)
I.m_list_wrapper.visible=true;T.update();assert(made==1 and T.failed)
print('Navigation: common-parent traversal, async load, release gate, cancellation and landing-page gating passed')
