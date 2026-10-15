-- Read-only native quest enumeration. Call shapes verified in GOG/v1.4 trace
-- and the user's private journal function export. No tracking/progression writes.
local M = {}
local function integer(n)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
        and n == math.floor(n)
end
function M.read(api)
    api = api or QUEST
    assert(type(api) == "table", "QUEST table unavailable")
    for _, key in ipairs({ "get_num_active_quests", "get_active_id", "get_stage", "get_quest_type", "get_current_quest" }) do
        assert(type(api[key]) == "function", "QUEST." .. key .. " unavailable")
    end
    local count = api.get_num_active_quests()
    assert(integer(count) and count >= 0 and count <= 10000, "invalid native quest count")
    local tracked = api.get_current_quest()
    local quests = {}
    for index = 0, count - 1 do
        local native_id = api.get_active_id(index)
        assert(native_id ~= nil, "missing quest ID at index " .. index)
        local stage = api.get_stage(native_id)
        assert(integer(stage), "invalid quest stage at index " .. index)
        -- This matches the journal's verified stage > 0 test. A native
        -- "active" entry at stage 0 or -1 is not a visible active journal quest.
        if stage > 0 then
            local quest_type = api.get_quest_type(native_id)
            if quest_type == nil or quest_type == "" then quest_type = "Main" end
            assert(type(quest_type) == "string", "invalid quest type")
            quests[#quests + 1] = { native_id = native_id, index = index,
                stage = stage, quest_type = quest_type, tracked = native_id == tracked }
        end
    end
    -- Opaque ui64 IDs remain untouched. This is not yet the full core snapshot:
    -- native targets, reveal permission and renderer integration remain unknown.
    return { quests = quests, enumerated = count }
end
return M
