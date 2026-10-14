-- Isolated synthetic host: no native function is called by these tests.
local total = 0
local function test(name, fn)
    fn(); total=total+1; print("PASS trace " .. name)
end
local path="mods/AllQuestMarkers/trace.lua"
local function host(sink)
    local calls, logs = 0, {}
    local env = setmetatable({ _VERSION="test-vm", debug=false }, {__index=_G})
    env._G=env
    env.print=sink or function(line)logs[#logs+1]=line end
    local original=function(...) calls=calls+1;return ... end
    env.QUEST={get_active_id=original}
    env.MAP={add_object_icon=original}
    local chunk=assert(loadfile(path));setfenv(chunk,env)
    local m=chunk()
    return env,m,original,function()return calls end,logs
end
test("installation executes no host operations",function()
    local e,m,f,c=host();assert(c()==0);assert(#m.hooks==2);assert(e.AQMTrace==m);assert(m.stop())
end)
test("argument identity and nil-containing multiple returns preserved",function()
    local e,m,f,c,logs=host();local t={a=4}
    local function pack(...)return {n=select('#',...),...}end
    local out=pack(e.QUEST.get_active_id(t,nil,17,nil))
    assert(c()==1 and out.n==4 and out[1]==t and out[2]==nil and out[3]==17 and out[4]==nil)
    assert(table.concat(logs,'\n'):find('n=4',1,true));assert(m.stop())
end)
test("native errors propagate without being swallowed or retried",function()
    local e,m=host();assert(m.stop());local calls=0
    e.QUEST.get_active_id=function()calls=calls+1;error('original-error')end
    local chunk=assert(loadfile(path));setfenv(chunk,e);m=chunk()
    local ok,err=pcall(e.QUEST.get_active_id);assert(not ok and err:find('original-error',1,true));assert(calls==1);assert(m.stop())
end)
test("failed logging cannot break host calls",function()
    local e,m,f,c=host(function()error('logger-error')end)
    assert(e.MAP.add_object_icon(11)==11 and c()==1);assert(m.stop())
end)
test("does not trigger table or userdata metamethods",function()
    local e,m=host();local t=setmetatable({x=1},{__index=function()error('bad-index')end,__tostring=function()error('bad-tostring')end})
    local u=newproxy(true);getmetatable(u).__tostring=function()error('bad-userdata-tostring')end
    assert(e.QUEST.get_active_id(t,u)==t);assert(m.stop())
end)
test("budget bounded; originals keep running after the limit",function()
    local e,m,f,c,logs=host();m.limit=4
    for i=1,50 do assert(e.QUEST.get_active_id(i)==i)end
    assert(c()==50 and m.records==4);m.reset();assert(m.records==0);assert(m.stop())
end)
test("stop restores identities and removes project namespace",function()
    local e,m,f=host();assert(m.stop());assert(e.QUEST.get_active_id==f and e.MAP.add_object_icon==f and e.AQMTrace==nil)
end)
test("repeat loading refuses to accumulate wrappers",function()
    local e,m=host();local saved=e.QUEST.get_active_id;local chunk=assert(loadfile(path));setfenv(chunk,e)
    assert(chunk()==m and e.QUEST.get_active_id==saved);assert(m.stop())
end)
test("teardown respects later third-party wrappers and makes ours inert",function()
    local e,m,f,c,logs=host();local ours=e.QUEST.get_active_id
    local later=function(...)return ours(...)end;e.QUEST.get_active_id=later
    assert(m.stop()==false and e.QUEST.get_active_id==later)
    local before=#logs;assert(later(7)==7 and c()==1 and #logs==before)
end)
print('RESULT trace '..total..' passed, 0 failed')
