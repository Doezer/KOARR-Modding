local base = "mods/AllQuestMarkers/"
local function load(name) return assert(loadfile(base .. name .. ".lua"))() end
local modules = { objectives = load("objectives"), coordinates = load("coordinates"), markers = load("markers") }
local controller = load("controller")
local passed, failed = 0, 0
local function test(name, f)
    local ok, err = pcall(f)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function config() return load("config") end
local function location(id, x, region)
    return { id = id or "dest", x = x or 10, y = 20, region = region or "r1",
        valid = true, known = true, revealed = true, native_visible = false }
end
local function quest(id, tracked)
    return { id = id or "q1", name = "Quest", state = "active", category = "side", tracked = tracked or false,
        objectives = { { id = "o1", valid = true, complete = false, locations = { location() } } } }
end
local function snapshot()
    return { session = "save1", region = "r1", quests = { quest("q1", true), quest("q2") } }
end
local function select(s, cfg)
    local list, err = modules.objectives.select(s, cfg or config()); assert(list, err); return list
end
local function host()
    local h = { data = snapshot(), view = { open = true, zoom = 1, pan = 0 }, callbacks = {}, live = {},
        creates = 0, removes = 0, logs = {}, native = { "vanilla-tracked", "fast-travel" } }
    local a = {}
    a.snapshot = function() if h.fail_read then error("read failed") end; return h.data end
    a.map_state = function() return h.view end
    a.project = function(m, v) return { x = m.x * v.zoom + v.pan, y = m.y * v.zoom } end
    a.renderer = {
        create = function(m)
            if h.fail_create then error("create failed") end
            h.creates = h.creates + 1
            local handle = { id = h.creates, marker = m }; h.live[handle] = m; return handle
        end,
        remove = function(handle)
            assert(h.live[handle], "attempt to remove a foreign/native/stale handle")
            if h.fail_remove then return false end
            h.removes = h.removes + 1; h.live[handle] = nil; return true
        end,
    }
    a.subscribe = function(event, callback)
        if h.fail_subscribe == event then error("subscribe failed") end
        assert(not h.callbacks[event], "listener accumulated")
        h.callbacks[event] = callback
        return function()
            if h.fail_unsubscribe then return false end
            h.callbacks[event] = nil; return true
        end
    end
    function h.emit(event) if h.callbacks[event] then h.callbacks[event]() end end
    function h.count() local n = 0; for _ in pairs(h.live) do n = n + 1 end; return n end
    function h.listener_count() local n = 0; for _ in pairs(h.callbacks) do n = n + 1 end; return n end
    h.adapter = a; h.config = config()
    h.controller = assert(controller.new(a, modules, h.config, function(level, s) h.logs[#h.logs+1] = level .. ":" .. s end))
    return h
end

test("all active quests and multiple objectives/destinations", function()
    local s = snapshot()
    s.quests[2].objectives[2] = { id = "o2", valid = true, complete = false,
        locations = { location("a"), location("b", 30) } }
    eq(#select(s), 4)
end)
test("completed failed and unknown quest states skipped", function()
    for _, state in ipairs({ "completed", "failed", "unknown" }) do
        local s = snapshot(); s.quests[1].state = state; eq(#select(s), 1)
    end
end)
test("incomplete and valid require explicit booleans", function()
    for _, patch in ipairs({ {complete=true}, {valid=false}, {complete="false"}, {valid="true"} }) do
        local s=snapshot(); for k,v in pairs(patch) do s.quests[1].objectives[1][k]=v end
        eq(#select(s),1)
    end
    local s=snapshot();s.quests[1].objectives[1].complete=nil;eq(#select(s),1)
end)
test("hidden unknown invalid or other-region destinations never pass", function()
    for _, field in ipairs({"known", "revealed", "valid"}) do
        for _, value in ipairs({false, "true"}) do
            local s=snapshot();s.quests[1].objectives[1].locations[1][field]=value;eq(#select(s),1)
        end
        local s=snapshot();s.quests[1].objectives[1].locations[1][field]=nil;eq(#select(s),1)
    end
    local s=snapshot();s.quests[1].objectives[1].locations[1].region="r2";eq(#select(s),1)
end)
test("native-visible and unknown native visibility skipped", function()
    local s=snapshot();s.quests[1].objectives[1].locations[1].native_visible=true;eq(#select(s),1)
    s.quests[1].objectives[1].locations[1].native_visible=nil;eq(#select(s),1)
end)
test("invalid coordinates and IDs skipped", function()
    for _, v in ipairs({0/0, math.huge, -math.huge, "10"}) do
        local s=snapshot();s.quests[1].objectives[1].locations[1].x=v;eq(#select(s),1)
    end
    local s=snapshot();s.quests[1].objectives[1].locations[1].id="";eq(#select(s),1)
end)
test("missing destination safe; malformed arrays reject snapshot", function()
    local s=snapshot();s.quests[1].objectives[1].locations={};eq(#select(s),1)
    s.quests[1].objectives[1].locations=nil;eq(modules.objectives.select(s,config()),nil)
    eq(modules.objectives.select({session="s",region="r",quests={[2]=quest()}},config()),nil)
end)
test("deduplicate exact destinations; preserve collocated distinct objectives", function()
    local s=snapshot();local ls=s.quests[1].objectives[1].locations
    ls[2]=location();eq(#select(s),2)
    ls[3]=location("another");eq(#select(s),3)
    ls[4]=location("dest",99);eq(modules.objectives.select(s,config()),nil)
end)
test("typed length-prefixed keys avoid ambiguous concatenation", function()
    local key=modules.objectives.key
    assert(key("a:b","c","d","e") ~= key("a","b:c","d","e"))
    assert(key(1,"o","l","r") ~= key("1","o","l","r"))
end)
test("category filter toggle and safety cap", function()
    local c=config();c.categories.side=false;eq(#select(snapshot(),c),0)
    c=config();c.enabled=false;eq(#select(snapshot(),c),0)
    c=config();c.max_markers=1;eq(modules.objectives.select(snapshot(),c),nil)
end)
test("open refresh is idempotent and subscriptions do not accumulate", function()
    local h=host();assert(h.controller:start());eq(h.count(),2);eq(h.listener_count(),6)
    h.emit("map_open");assert(h.controller:start());eq(h.creates,2);eq(h.listener_count(),6)
    assert(h.controller:stop());eq(h.count(),0);eq(h.listener_count(),0)
    assert(h.controller:start());eq(h.listener_count(),6);assert(h.controller:stop())
end)
test("tracked switching preserves other markers and never touches native handles", function()
    local h=host();assert(h.controller:start())
    h.data.quests[1].tracked=false;h.data.quests[2].tracked=true;h.emit("quests_changed")
    eq(h.count(),2);eq(h.native[1],"vanilla-tracked");eq(h.native[2],"fast-travel")
    assert(h.controller:stop())
end)
test("complete accept and invalidate synchronize owned markers", function()
    local h=host();assert(h.controller:start())
    h.data.quests[1].objectives[1].complete=true;h.emit("quests_changed");eq(h.count(),1)
    h.data.quests[3]=quest("q3");h.emit("quests_changed");eq(h.count(),2)
    h.data.quests[2].objectives[1].valid=false;h.emit("quests_changed");eq(h.count(),1)
    assert(h.controller:stop())
end)
test("pan zoom always reproject; culling removes offscreen markers", function()
    local h=host();assert(h.controller:start());h.view.zoom=2;h.view.pan=5;h.emit("map_view_changed")
    for _, m in pairs(h.live) do eq(m.screen_x,25);eq(m.screen_y,40) end
    h.adapter.project=function() return nil end;h.emit("map_view_changed");eq(h.count(),0)
    assert(h.controller:stop())
end)
test("save load and region changes drop prior session handles", function()
    local h=host();assert(h.controller:start());h.data.session="save2";h.emit("save_loaded")
    eq(h.count(),2);eq(h.removes,2)
    h.data.region="r2";h.emit("region_changed");eq(h.count(),0)
    h.data.quests[1].objectives[1].locations[1].region="r2";h.emit("quests_changed");eq(h.count(),1)
    assert(h.controller:stop())
end)
test("close disable and uninstall cleanup", function()
    local h=host();assert(h.controller:start());h.view.open=false;h.emit("map_close");eq(h.count(),0)
    h.view.open=true;h.emit("map_open");eq(h.count(),2)
    h.config.enabled=false;assert(h.controller:refresh());eq(h.count(),0)
    assert(h.controller:stop());eq(h.listener_count(),0)
    h.emit("map_open");eq(h.count(),0)
end)
test("read failure clears stale overlay and can recover", function()
    local h=host();assert(h.controller:start());h.fail_read=true;eq(h.controller:refresh(),false);eq(h.count(),0)
    h.fail_read=false;assert(h.controller:refresh());eq(h.count(),2);assert(h.controller:stop())
end)
test("invalid projection clears overlay rather than retaining stale coordinates", function()
    local h=host();assert(h.controller:start());h.adapter.project=function() return {x=0/0,y=1} end
    eq(h.controller:refresh(),false);eq(h.count(),0);assert(h.controller:stop())
end)
test("renderer create failure is reported and retried without duplication", function()
    local h=host();h.fail_create=true;eq(h.controller:start(),false);eq(h.count(),0);eq(h.listener_count(),0)
    h.fail_create=false;assert(h.controller:start());eq(h.count(),2);assert(h.controller:stop())
end)
test("remove failure retains ownership and retries cleanup", function()
    local h=host();assert(h.controller:start());h.fail_remove=true
    h.view.zoom=2;eq(h.controller:refresh(),false);eq(h.count(),2);eq(h.creates,2)
    eq(h.controller:stop(),false);eq(h.controller:start(),false)
    h.fail_remove=false;assert(h.controller:stop());eq(h.count(),0)
end)
test("subscription failure unwinds earlier listeners", function()
    local h=host();h.fail_subscribe="quests_changed";eq(h.controller:start(),false);eq(h.listener_count(),0)
end)
test("listener cleanup failure can be retried; callbacks inert while stopping", function()
    local h=host();assert(h.controller:start());h.fail_unsubscribe=true;eq(h.controller:stop(),false)
    h.emit("map_open");eq(h.count(),0);h.fail_unsubscribe=false;assert(h.controller:stop());eq(h.listener_count(),0)
end)
test("reentrant host event is coalesced rather than recursively creating markers", function()
    local h=host();local original=h.adapter.snapshot;local reads=0
    h.adapter.snapshot=function() reads=reads+1;h.emit("quests_changed");return original() end
    assert(h.controller:start());eq(reads,2);eq(h.count(),2);eq(h.creates,2);assert(h.controller:stop())
end)
test("missing adapter functions fail before listeners installed", function()
    eq(controller.new({},modules,config(),function()end),nil)
end)
test("probe does not call functions or metamethods and handles cycles", function()
    local oldprint=print;local captured={};print=function(s)captured[#captured+1]=s end
    local probe=load("probe");print=oldprint
    local calls=0;local root={quest={get_active_id=function()calls=calls+1 end}}
    root.quest.loop=root
    setmetatable(root.quest,{__index=function()error("index invoked")end,__tostring=function()error("tostring invoked")end})
    local r=assert(probe.scan(root,"test",function(s)captured[#captured+1]=s end));eq(calls,0);assert(r.symbols>=2)
    local found=false;for _,s in ipairs(captured)do if s:find("root.quest.get_active_id : function",1,true)then found=true end end
    assert(found)
end)
test("probe bounds huge tables", function()
    local oldprint=print;print=function()end;local probe=load("probe");print=oldprint
    local root={};for i=1,12000 do root["quest"..i]=i end
    local r=probe.scan(root,"large",function()end);assert(r.truncated);assert(r.symbols<=500);assert(r.inspected<=10000)
end)
test("bootstrap starts no game hooks and rejects an incomplete adapter", function()
    local oldprint=print;print=function()end;local m=load("bootstrap");print=oldprint
    eq(m.status,"game-adapter-unverified");eq(m.refresh(),false);eq(m.attach({}),false)
    assert(m.detach());assert(m.set_enabled(false));eq(m.set_enabled("false"),false)
end)
print(string.format("RESULT %d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
