local reader=assert(loadfile('mods/AllQuestMarkers/quest_reader.lua'))()
local ids={newproxy(),newproxy(),newproxy(),newproxy()}
local stages={[ids[1]]=0,[ids[2]]=10,[ids[3]]=-1,[ids[4]]=60}
local indices,reads={},{}
local api={
 get_num_active_quests=function()return 4 end,
 get_current_quest=function()return ids[4]end,
 get_active_id=function(index)indices[#indices+1]=index;return ids[index+1]end,
 get_stage=function(id)reads[#reads+1]=id;return stages[id]end,
 get_quest_type=function(id)assert(id==ids[2]or id==ids[4]);return id==ids[2]and 'Side'or ''end,
}
local s=reader.read(api)
assert(s.enumerated==4 and #s.quests==2 and #reads==4)
for i=1,4 do assert(indices[i]==i-1 and reads[i]==ids[i])end
assert(s.quests[1].native_id==ids[2] and s.quests[1].quest_type=='Side' and not s.quests[1].tracked)
assert(s.quests[2].native_id==ids[4] and s.quests[2].quest_type=='Main' and s.quests[2].tracked)
print('PASS native reader filters inactive stages, uses zero-based indices and preserves opaque IDs')
api.get_num_active_quests=function()return 0 end;assert(#reader.read(api).quests==0)
api.get_num_active_quests=function()return 0/0 end;assert(not pcall(reader.read,api))
api.get_num_active_quests=function()return 10001 end;assert(not pcall(reader.read,api))
api.get_num_active_quests=function()return 1 end;api.get_stage=function()return '10'end
assert(not pcall(reader.read,api))
print('PASS native reader rejects invalid counts/stages and supports an empty journal')
