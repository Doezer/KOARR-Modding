-- Startup must not call the game loader, package loader or native helper functions.
-- Match the missing standard-library function observed in the target game log.
math.floor=nil
local initialize,profile,poll,suspend,shows=0,0,0,0,0
local outcome='success'
local bridge_calls=0
QuestHiderNative={self_test=function(s)bridge_calls=bridge_calls+1;return s end,
 initialize=function()
  initialize=initialize+1
  if outcome=='throw' then error('initialization exception') end
  return outcome=='success' and 'QuestHider' or nil
 end,
 profile=function()profile=profile+1;return true end,
 poll=function()poll=poll+1;return nil end,
 suspend=function()suspend=suspend+1 end,
 is_hidden=function()return nil end,set_hidden=function()return nil end,save_error=function()return nil end}
loadfile=function()error('Game asset loader must not be called by bootstrap')end
package.loadlib=function()error('Native library loader must not be called by bootstrap')end
PLAYER={get_player_name=function()return 'Hero' end}
QUEST={get_quest_key_as_int=function(id)return id end}
WINDOW={is_visible=function()return true end}
MAP={set_map_window_region=function()return 'map' end}
minimap_win={on_update_event=function()return 'minimap' end}
local original=function(event)
 if event=='SHOW' then shows=shows+1 end
 return nil,'original'
end
quests_win={m_inited=true,m_window={},m_quest_data={quests={}},
 get_selected_quest=function()return nil end,rebuild_quest_list=function()end,
 on_window_event=original,on_update_event=function()end}
-- Missing/malformed framework-loaded config disables without native effects.
assert(dofile('mods/QuestHider/bootstrap.lua')==false)
assert(initialize==0 and quests_win.on_window_event==original)
QuestHiderConfig={toggle_key=117,hidden_list_key=117,profile=''}
assert(dofile('mods/QuestHider/bootstrap.lua')==false)
assert(initialize==0 and quests_win.on_window_event==original)
for _,key in ipairs({0,256,117.5,'117',math.huge,0/0}) do
 QuestHiderConfig={toggle_key=key,hidden_list_key=118,profile=''}
 assert(dofile('mods/QuestHider/bootstrap.lua')==false)
 assert(initialize==0 and quests_win.on_window_event==original)
end
dofile('mods/QuestHider/config.lua')
local S=dofile('mods/QuestHider/bootstrap.lua')
assert(type(S)=='table' and not S.native_ready)
for i=1,100 do assert(minimap_win.on_update_event()=='minimap')end
assert(MAP.set_map_window_region()=='map')
assert(not S.toggle_selected() and not S.toggle_view())
-- ledger_win can acquire its functions after quests_win has loaded.
local reminder=function()return 'original reminder' end
ledger_win={set_reminder=reminder}
assert(dofile('mods/QuestHider/bootstrap.lua')==S)
assert(ledger_win.set_reminder~=reminder)
assert(ledger_win.set_reminder()=='original reminder')
quests_win.on_window_event('END_INIT')
assert(initialize==0 and profile==0 and poll==0 and suspend==0 and bridge_calls==0)
local a,b=quests_win.on_window_event('SHOW')
assert(a==nil and b=='original' and S.native_ready and initialize==1 and shows==1)
quests_win.on_window_event('SHOW');assert(initialize==1 and shows==2)
S.detach()
for _,mode in ipairs({'disabled','throw'})do
 outcome=mode
 S=dofile('mods/QuestHider/bootstrap.lua')
 local before=initialize
 local c,d=quests_win.on_window_event('SHOW')
 assert(c==nil and d=='original' and not S.native_ready and initialize==before+1)
 quests_win.on_window_event('SHOW');assert(initialize==before+1)
 S.detach()
end
for _,mode in ipairs({'wrong-version','missing-result','error'})do
 QuestHiderNative.self_test=function()
  if mode=='error' then error('bridge failure')end
  return mode=='wrong-version' and 'old bridge' or nil
 end
 S=dofile('mods/QuestHider/bootstrap.lua')
 local before=initialize
 local c,d=quests_win.on_window_event('SHOW')
 assert(c==nil and d=='original' and not S.native_ready and initialize==before)
 S.detach()
end
print('Quest Hider startup: no nested loaders/native startup calls; deferred failures preserve journal')
