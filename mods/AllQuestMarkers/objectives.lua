-- Pure logic over normalized snapshots. No game functions are assumed here.
local M = {}
local function finite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end
local function id(v)
    return (type(v) == "string" and #v > 0 and #v <= 256)
        or (finite(v) and v == math.floor(v))
end
local function token(v)
    local s = tostring(v)
    return type(v) .. ":" .. #s .. ":" .. s
end
function M.key(q, o, l, region)
    return token(q) .. token(o) .. token(l) .. token(region)
end
local function array(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then return false end
        count = count + 1
    end
    for i = 1, count do if rawget(t, i) == nil then return false end end
    return true
end
function M.select(snapshot, config)
    if type(snapshot) ~= "table" or not id(snapshot.session)
        or not id(snapshot.region) or not array(snapshot.quests) then
        return nil, "invalid snapshot/session/region/quest array"
    end
    local result, seen = {}, {}
    if not config.enabled then return result end
    for _, q in ipairs(snapshot.quests) do
        if type(q) ~= "table" or not id(q.id) then return nil, "invalid quest" end
        if q.state == "active" and config.categories[q.category] == true then
            if not array(q.objectives) then return nil, "invalid objective array" end
            for _, o in ipairs(q.objectives) do
                if type(o) ~= "table" or not id(o.id) then return nil, "invalid objective" end
                if o.complete == false and o.valid == true then
                    if not array(o.locations) then return nil, "invalid location array" end
                    for _, l in ipairs(o.locations) do
                        if type(l) ~= "table" then return nil, "invalid location" end
                        -- Reveal permission must come from the game's own rule. Unknown fails closed.
                        if id(l.id) and l.region == snapshot.region and l.known == true
                            and l.revealed == true and l.valid == true
                            and l.native_visible == false and finite(l.x) and finite(l.y) then
                            local k = M.key(q.id, o.id, l.id, l.region)
                            local marker = { key = k, quest_id = q.id, objective_id = o.id,
                                location_id = l.id, name = q.name, category = q.category,
                                tracked = q.tracked == true, region = l.region, x = l.x, y = l.y }
                            if seen[k] then
                                local old = seen[k]
                                if old.x ~= marker.x or old.y ~= marker.y then
                                    return nil, "conflicting duplicate destination " .. k
                                end
                            else
                                seen[k] = marker
                                result[#result + 1] = marker
                                if #result > config.max_markers then return nil, "marker safety limit exceeded" end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.key < b.key end)
    return result
end
return M
