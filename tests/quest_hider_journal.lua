local stored,profile,fail,pressed={},'Hero',false,{}
QuestHiderNative={initialize=function()return true end,profile=function()return true end,
 suspend=function()end,is_hidden=function(k)return stored[profile..k] end,
 set_hidden=function(k,a)if fail then return nil end;stored[profile..k]=a=='hide' or nil;return true end,
 poll=function(k)local v=pressed[k];pressed[k]=nil;return v end}
PLAYER={get_player_name=function()return profile end}
QUEST={get_quest_key_as_int=function(id)return id end,get_name=function(id)return 'Quest '..id end}
local visible,selected,rendered,crash=true,2,{},false
WINDOW={is_visible=function()return visible end,find_static=function(w)return w end,
 set_label_text=function(w,t)w.label=t end}
local rows={{id='Main',collapsed=false},{id=42,visible=true},{id=43,visible=true},
 {id=44,visible=false},{id=45,visible=true,finished=true}}
local qw={m_inited=true,m_window={},m_quest_data={quests=rows}}
quests_win=qw
qw.get_selected_quest=function()return rows[selected]end
qw.set_selected_quest=function(i)selected=i end
qw.get_starting_selected_quest_index=function()return selected end
qw.add_template=function(i)return {id=i},nil,'tail' end
qw.rebuild_quest_list=function()
 rendered={};for i,r in ipairs(rows)do if r.collapsed~=nil or r.visible then rendered[i]=true end end
 if crash then error('render failure')end
 qw.set_selected_quest(selected)
 return nil,'tail'
end
qw.on_window_event=function()end
qw.on_update_event=function()return nil,'update' end
local original=qw.rebuild_quest_list
local S=dofile('mods/QuestHider/bootstrap.lua')
qw.on_window_event('SHOW')
assert(S.toggle_selected());assert(stored.Hero42);assert(not rendered[2] and rendered[3]);assert(rows[2].visible)
assert(selected==3)
local a,b=qw.rebuild_quest_list();assert(a==nil and b=='tail')
assert(S.toggle_view());assert(rendered[2] and not rendered[3]);assert(not rendered[4]);assert(selected==2)
local w,x,y=qw.add_template(2);assert(w.label=='[Hidden] Quest 42' and x==nil and y=='tail')
assert(S.toggle_selected());assert(not stored.Hero42);assert(not rendered[2])
S.toggle_view();selected=3;fail=true;assert(not S.toggle_selected());assert(not stored.Hero43);fail=false
selected=5;assert(not S.toggle_selected())
crash=true;local ok=pcall(qw.rebuild_quest_list);assert(not ok and rows[2].visible and rows[4].visible==false);crash=false
selected=2;visible=false;pressed['117']=true;qw.on_update_event(1,{});assert(not stored.Hero42)
visible=true;qw.on_update_event(1,{});assert(stored.Hero42)
profile='Other';S.sync_profile();qw.rebuild_quest_list();assert(rendered[2])
local count=#S.hooks;assert(dofile('mods/QuestHider/bootstrap.lua')==S and #S.hooks==count)
S.detach();assert(qw.rebuild_quest_list==original and not S.enabled)
print('Quest Hider journal checks passed')
