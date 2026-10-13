-- Read-only structure inspection. Never call an unknown engine function, index
-- userdata, invoke __index/__pairs/__tostring, or inspect the debug registry.
local M = {}
local candidates = {
    "get_num_active_quests", "get_active_id", "get_current_quest", "is_quest_active",
    "is_quest_completed", "get_is_failed", "get_stage", "get_num_stage_subtasks",
    "get_is_stage_subtask_complete", "get_target_indexes", "get_target_types",
    "world_to_window_coords", "window_to_world_coords", "add_object_icon",
    "add_gor_icon", "set_object_icon_visible", "set_gor_icon_visible",
    "set_object_world_location", "register_map_window", "set_map_window_region",
}
local excluded = { _G = true, package = true, debug = true, io = true, os = true,
    math = true, string = true, table = true, coroutine = true, AllQuestMarkers = true }
local function relevant(k)
    local s = string.lower(k)
    for _, word in ipairs({ "quest", "objective", "subtask", "map", "marker", "window", "region", "target", "event" }) do
        if string.find(s, word, 1, true) then return true end
    end
    for _, name in ipairs(candidates) do if k == name then return true end end
    return false
end
function M.scan(root, label, sink)
    root, sink = root or _G, sink or print
    if type(root) ~= "table" then return nil, "root must be a plain Lua table" end
    local count, inspected, seen, queue = 0, 0, {}, { { root, "root", 0 } }
    local function emit(s) pcall(sink, "[AllQuestMarkers][probe] " .. s) end
    emit("BEGIN " .. (type(label) == "string" and label or "manual") .. " vm=" .. tostring(_VERSION))
    emit("symbol names/types only; presence does not verify signatures or Re-Reckoning compatibility")
    local index = 1
    while index <= #queue and inspected < 10000 and count < 500 do
        local item = queue[index]; index = index + 1
        if not seen[item[1]] then
            seen[item[1]] = true
            local k, v = next(item[1])
            while k ~= nil and inspected < 10000 and count < 500 do
                inspected = inspected + 1
                if type(k) == "string" and #k < 160 and not excluded[k] then
                    local path = item[2] .. "." .. k
                    if relevant(k) or (item[3] > 0 and relevant(item[2])) then
                        emit(path .. " : " .. type(v)); count = count + 1
                    end
                    if type(v) == "table" and item[3] < 2 and #queue < 200 then
                        queue[#queue + 1] = { v, path, item[3] + 1 }
                    end
                end
                k, v = next(item[1], k)
            end
        end
    end
    local truncated = index <= #queue or inspected >= 10000 or count >= 500 or #queue >= 200
    emit("END symbols=" .. count .. " inspected=" .. inspected .. " truncated=" .. tostring(truncated))
    emit("userdata methods/metatables and unavailable lexical modules were intentionally not inspected")
    return { symbols = count, inspected = inspected, truncated = truncated }
end
M.scan(_G, "manual-load")
return M
