-- Temporary passive call tracer. Only forwards calls initiated by the game.
-- No quest setters, map operations, native getters or hidden-data reveals are
-- initiated by this script. Loading installs transient Lua table wrappers.
local existing = rawget(_G, "AQMTrace")
if existing ~= nil then
    print("[AllQuestMarkers][trace] already present; stop it before loading again")
    return existing
end
local M = { active = true, records = 0, limit = 300, hooks = {}, sequence = 0 }
local types, format, concat = type, string.format, table.concat
local raw_next, raw_get, raw_set, raw_equal = next, rawget, rawset, rawequal
local unpack_values, count_args = unpack, select
local output, protect = print, pcall
local opaque_ids, next_opaque = {}, 0
local function emit(message)
    protect(output, "[AllQuestMarkers][trace] " .. message)
end
local function opaque(value, kind)
    local id = opaque_ids[value]
    if not id then next_opaque = next_opaque + 1; id = next_opaque; opaque_ids[value] = id end
    return kind .. "#" .. id
end
local function describe(value, depth, seen)
    local kind = types(value)
    if kind == "nil" then return "nil" end
    if kind == "number" or kind == "boolean" then return tostring(value) end
    if kind == "string" then
        local clipped = string.sub(value, 1, 100)
        return format("%q", clipped) .. (#value > 100 and "..." or "")
    end
    if kind ~= "table" then return opaque(value, kind) end
    local label = opaque(value, "table")
    if depth == 0 or seen[value] then return label end
    seen[value] = true
    local fields, key, child = {}, raw_next(value)
    while key ~= nil and #fields < 12 do
        fields[#fields + 1] = describe(key, 0, seen) .. "=" .. describe(child, depth - 1, seen)
        key, child = raw_next(value, key)
    end
    if key ~= nil then fields[#fields + 1] = "..." end
    seen[value] = nil
    return label .. "{" .. concat(fields, ",") .. "}"
end
local function values(...)
    local n = count_args("#", ...)
    local args, pieces = { ... }, {}
    for i = 1, math.min(n, 10) do pieces[i] = describe(args[i], 1, {}) end
    if n > 10 then pieces[#pieces + 1] = "..." end
    return "n=" .. n .. " [" .. concat(pieces, ",") .. "]"
end
local function record(message)
    if not M.active or M.records >= M.limit then return end
    M.records = M.records + 1
    emit(message)
    if M.records == M.limit then emit("LIMIT reached; forwarding continues without logging") end
end
local function log_record(prefix, ...)
    -- Logging must never stop an original engine call or change its returns.
    protect(function(...) record(prefix .. values(...)) end, ...)
end
local groups = {
    { "QUEST", { "get_num_active_quests", "get_active_id", "get_current_quest",
        "get_stage", "get_num_stage_subtasks", "get_is_stage_subtask_complete",
        "get_target_indexes", "get_target_types" } },
    { "MAP", { "register_map_window", "unregister_map_window", "set_map_window_region",
        "add_object", "add_gor", "add_object_icon", "add_gor_icon",
        "set_object_icon_visible", "set_gor_icon_visible", "set_object_world_location",
        "world_to_window_coords", "remove_object_icon", "remove_gor_icon" } },
    { "map_manager", { "add_object", "add_object_specific", "add_gor_specific",
        "change_icon_properties", "remove_object", "remove_object_specific", "remove_gor_specific" } },
    { "map_data", { "lookup_location_data", "is_world_map_region" } },
}
local function install(owner, key, name)
    local original = raw_get(owner, key)
    if types(original) ~= "function" then emit("SKIP " .. name .. " not a raw function"); return end
    local wrapped
    wrapped = function(...)
        if not M.active or M.records >= M.limit then return original(...) end
        M.sequence = M.sequence + 1
        local sequence = M.sequence
        log_record("CALL " .. sequence .. " " .. name .. " ", ...)
        local function finish(...)
            log_record("RETURN " .. sequence .. " " .. name .. " ", ...)
            return ...
        end
        -- The original is called once, with exactly the caller's arguments.
        -- Do not pcall it: errors propagate as usual. finish preserves nil slots.
        return finish(original(...))
    end
    raw_set(owner, key, wrapped)
    M.hooks[#M.hooks + 1] = { owner = owner, key = key, name = name, original = original, wrapped = wrapped }
    emit("HOOK " .. name)
end
function M.reset()
    M.records = 0
    emit("RESET budget=" .. M.limit)
end
function M.stop()
    M.active = false
    local changed = 0
    for _, h in ipairs(M.hooks) do
        if raw_equal(raw_get(h.owner, h.key), h.wrapped) then
            raw_set(h.owner, h.key, h.original)
        else
            changed = changed + 1
            emit("NOT RESTORED " .. h.name .. ": another mod replaced the binding; restart game for full cleanup")
        end
    end
    emit("STOP restored own bindings; conflicts=" .. changed)
    if changed == 0 and raw_equal(raw_get(_G, "AQMTrace"), M) then raw_set(_G, "AQMTrace", nil) end
    return changed == 0
end
-- Keep diagnostics to useful module source metadata when standard debug is exposed.
local function source_info(owner, key, name)
    local debug_table = raw_get(_G, "debug")
    local getter = types(debug_table) == "table" and raw_get(debug_table, "getinfo")
    if types(getter) ~= "function" then return end
    protect(function()
        local fn = raw_get(owner, key)
        if types(fn) ~= "function" then return end
        local info = getter(fn, "S")
        if types(info) == "table" then
            emit("SOURCE " .. name .. " " .. describe(raw_get(info, "source"), 0, {})
                .. " lines=" .. describe(raw_get(info, "linedefined"), 0, {})
                .. ":" .. describe(raw_get(info, "lastlinedefined"), 0, {}))
        end
    end)
end
emit("BEGIN passive-v1 vm=" .. tostring(_VERSION) .. " budget=" .. M.limit)
raw_set(_G, "AQMTrace", M)
local ok, err = protect(function()
    for _, group in ipairs(groups) do
        local owner = raw_get(_G, group[1])
        if types(owner) == "table" then
            for _, key in ipairs(group[2]) do
                source_info(owner, key, group[1] .. "." .. key)
                install(owner, key, group[1] .. "." .. key)
            end
        else emit("SKIP module " .. group[1]) end
    end
end)
if not ok then emit("INSTALL FAILED: " .. describe(err, 0, {})); M.stop(); return M end
emit("READY hooks=" .. #M.hooks .. "; open journal, then world map. Stop: AQMTrace.stop()")
return M
