local passed = 0
local function test(name, fn) fn();passed=passed+1;print('PASS inspect '..name)end
local path='mods/AllQuestMarkers/inspect.lua'
local function host(options)
    options=options or {}
    local files,calls,logs={},0,{}
    local env=setmetatable({_VERSION='test-vm'}, {__index=_G});env._G=env
    env.string=string
    env.print=function(message)logs[#logs+1]=message end
    env.minimap_win={marker=function(a,b)calls=calls+1;return a,b end}
    env.map_manager={add=function()calls=calls+1 end}
    env.quests_win={native=print}
    if options.existing then files['AllQuestMarkers-inspection-001.txt']='user-file' end
    env.io={open=function(name,mode)
        if mode=='rb' then
            if options.denied then return nil,'permission denied',13 end
            if files[name] then return {close=function()return true end}end
            return nil,'no such file',2
        end
        assert(mode=='wb' and files[name]==nil,'overwrote existing file')
        files[name]=''
        return {write=function(self,data)
            if options.write_fail then return nil,'disk full' end
            files[name]=files[name]..data;return self
        end,close=function()return true end}
    end}
    if options.no_dump then env.string={} end
    if options.no_io then env.io={} end
    if options.tracer then env.AQMTrace={} end
    local f=assert(loadfile(path));setfenv(f,env)
    local result=f()
    return result,files,calls,logs,env
end
test('exports function bytecode without invoking functions',function()
    local r,files,calls,logs,env=host();assert(r.ok and r.functions==2 and r.skipped==1 and calls==0)
    local s=files[r.path];assert(s:find('AQM-INSPECTION 1',1,true));assert(s:find('DONE functions=2',1,true))
    local encoded=s:match('FUNCTION minimap_win.marker %d+\n(.-)END\n');assert(encoded)
    encoded=encoded:gsub('%s','');local binary=encoded:gsub('..',function(h)return string.char(tonumber(h,16))end)
    assert(binary==string.dump(env.minimap_win.marker));assert(binary:sub(1,4)=='\27Lua')
end)
test('preserves existing output and chooses next filename',function()
    local r,files=host({existing=true});assert(r.path=='AllQuestMarkers-inspection-002.txt')
    assert(files['AllQuestMarkers-inspection-001.txt']=='user-file')
end)
test('does not overwrite a file whose readability cannot be checked',function()
    local r,files,calls=host({denied=true});assert(not r.ok and r.reason=='cannot-check-output');assert(next(files)==nil and calls==0)
end)
test('missing dump support is reported without creating files',function()
    local r,files,calls=host({no_dump=true});assert(not r.ok and r.reason=='missing-standard-library');assert(next(files)==nil and calls==0)
end)
test('refuses export while wrappers are present',function()
    local r,files,calls=host({tracer=true});assert(not r.ok and r.reason=='tracer-still-present');assert(next(files)==nil and calls==0)
end)
test('write failure reports incomplete output rather than success',function()
    local r=host({write_fail=true});assert(not r.ok and r.reason=='write-failed')
end)
test('missing io.open exports complete bytecode to console without touching files',function()
    local r,files,calls,logs,env=host({no_io=true})
    assert(r.ok and r.path=='console' and r.functions==2 and calls==0 and next(files)==nil)
    local data={};local begin_seen,end_seen=false,false
    for _,line in ipairs(logs)do
        if line:find('BEGIN console-export-v2',1,true)then begin_seen=true end
        if line:find('END console-export-v2',1,true)then end_seen=true end
        local content=line:match('^%[AllQuestMarkers%]%[inspect%-data%] (.*)$')
        if content then data[#data+1]=content end
    end
    assert(begin_seen and end_seen)
    local report=table.concat(data,'\n')..'\n'
    local encoded=report:match('FUNCTION minimap_win.marker %d+\n(.-)END\n');assert(encoded)
    encoded=encoded:gsub('%s','')
    local bytes=encoded:gsub('..',function(h)return string.char(tonumber(h,16))end)
    assert(bytes==string.dump(env.minimap_win.marker))
end)
print('RESULT inspect '..passed..' passed, 0 failed')
