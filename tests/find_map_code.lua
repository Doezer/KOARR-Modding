local logs,calls={},0
local env={_VERSION='synthetic',ipairs=ipairs,next=next,type=type,pcall=pcall,rawget=rawget,assert=assert,tostring=tostring,string=string,table=table}
env._G=env
env.print=function(s)logs[#logs+1]=s end
env.unexpected_module={render=function()calls=calls+1;return 'get_target_indexes'end,unrelated=function()calls=calls+1;return 'unrelated'end}
local chunk=assert(loadfile('mods/AllQuestMarkers/find_map_code.lua'));setfenv(chunk,env);chunk()
assert(calls==0)
local text=table.concat(logs,'\n')
assert(text:find('AQM-FUNCTION unexpected_module.render',1,true))
assert(not text:find('AQM-FUNCTION unexpected_module.unrelated',1,true))
assert(text:find('matches=1',1,true)and text:find('limited=false',1,true))
print('PASS source search locates unknown modules by bytecode constants without executing their functions')
