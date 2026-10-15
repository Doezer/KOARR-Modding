-- Local inspection export only. No hooks and no calls to engine game functions.
-- Output may contain proprietary compiled scripts. Share privately for analysis;
-- do not distribute it with a mod or upload it to a public repository.
local function emit(message)
    pcall(print, "[AllQuestMarkers][inspect] " .. message)
end
if rawget(_G, "AQMTrace") ~= nil then
    emit("Stop the tracer first with AQMTrace.stop(), or restart the game.")
    return { ok = false, reason = "tracer-still-present" }
end
local strings, files = rawget(_G, "string"), rawget(_G, "io")
local dump = type(strings) == "table" and rawget(strings, "dump")
local open = type(files) == "table" and rawget(files, "open")
if type(dump) ~= "function" then
    emit("Unavailable: standard string.dump; no game functions were called.")
    return { ok = false, reason = "missing-standard-library" }
end
local path, file
local console = type(open) ~= "function"
if console then
    path = "console"
    emit("BEGIN console-export-v2; file writing unavailable, exporting to console")
    file = {
        write = function(self, text)
            for line in text:gmatch("[^\r\n]+") do
                print("[AllQuestMarkers][inspect-data] " .. line)
            end
            return self
        end,
        close = function() return true end,
    }
else
    for i = 1, 20 do
        local candidate = string.format("AllQuestMarkers-inspection-%03d.txt", i)
        local existing, read_error, read_code = open(candidate, "rb")
        if existing then
            existing:close()
        elseif read_code == 2 then -- ENOENT; never overwrite an unreadable existing file.
            local created = open(candidate, "wb")
            if created then path, file = candidate, created; break end
        else
            emit("Cannot safely check " .. candidate .. ": " .. tostring(read_error))
            return { ok = false, reason = "cannot-check-output" }
        end
    end
end
if not file then
    emit("Cannot create a new inspection file in the game's working directory.")
    return { ok = false, reason = "cannot-create-output" }
end
local function write(text)
    local ok, err = file:write(text)
    if not ok then error("inspection write failed: " .. tostring(err)) end
end
local function hex(data)
    return (data:gsub(".", function(c) return string.format("%02x", string.byte(c)) end))
end
local total, dumped, skipped = 0, 0, 0
local requested = ...
local allowed = { minimap_win=true, map_manager=true, quests_win=true, map_data=true, target_win_manager=true }
local modules = { "minimap_win", "map_manager", "quests_win" }
if type(requested) == "string" and allowed[requested] then modules = { requested } end
local ok, err = pcall(function()
    write("AQM-INSPECTION 1\nVM " .. tostring(_VERSION) .. "\n")
    for _, name in ipairs(modules) do
        local owner = rawget(_G, name)
        if type(owner) ~= "table" then
            write("MISSING " .. name .. "\n")
        else
            local keys, key, value = {}, next(owner)
            while key ~= nil do
                if type(key) == "string" and key:match("^[A-Za-z_][A-Za-z_0-9]*$")
                    and type(value) == "function" then keys[#keys + 1] = key end
                key, value = next(owner, key)
            end
            table.sort(keys)
            for _, key in ipairs(keys) do
                local fn = rawget(owner, key)
                local success, data = pcall(dump, fn)
                if success and type(data) == "string" and #data > 0
                    and #data <= 131072 and total + #data <= 1048576 and dumped < 256 then
                    -- Serialize only; the exported function is never executed.
                    write("FUNCTION " .. name .. "." .. key .. " " .. #data .. "\n")
                    for i = 1, #data, 256 do write(hex(data:sub(i, i + 255)) .. "\n") end
                    write("END\n")
                    total, dumped = total + #data, dumped + 1
                else
                    skipped = skipped + 1
                    write("SKIP " .. name .. "." .. key .. " "
                        .. (success and "empty-or-size-limit" or "dump-unavailable") .. "\n")
                end
            end
        end
    end
    write("DONE functions=" .. dumped .. " bytes=" .. total .. " skipped=" .. skipped .. "\n")
end)
local closed, close_error = file:close()
if not ok or not closed then
    emit("Export failed: " .. tostring(ok and close_error or err) .. "; incomplete file: " .. path)
    return { ok = false, path = path, reason = "write-failed" }
end
emit((console and "END console-export-v2" or ("SAVED " .. path)) .. " functions=" .. dumped .. " bytes=" .. total .. " skipped=" .. skipped)
if dumped == 0 then
    emit("No functions exported: this VM may not support dumping these functions. Send this console output.")
elseif console then
    emit("Copy the console output from BEGIN console-export-v2 through END console-export-v2 and share privately.")
else
    emit("The file is beside koa.exe when launched from the game folder. Upload it privately here; do not publish it.")
end
return { ok = dumped > 0, path = path, functions = dumped, bytes = total, skipped = skipped }
