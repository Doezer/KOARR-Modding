-- Inspect loaded Lua bytecode for relevant API names. No engine calls or hooks.
assert(type(string.dump) == "function", "string.dump unavailable")
if rawget(_G, "AQMTrace") ~= nil then
    print("Stop AQMTrace before exporting original functions.")
    return
end
local needles = { "get_target_indexes", "get_target_types", "add_object_icon", "add_gor_icon" }
local skip = { _G=true, package=true, debug=true, io=true, os=true, string=true,
    table=true, math=true, coroutine=true }
local seen, queue = {}, {}
for name, owner in next, _G do
    if type(name) == "string" and not skip[name] and type(owner) == "table" then
        queue[#queue + 1] = { name=name, owner=owner }
    end
end
table.sort(queue, function(a,b) return a.name < b.name end)
local examined, scanned, matched, emitted, tables = 0, 0, 0, 0, 0
print("AQM-SEARCH BEGIN")
for _, item in ipairs(queue) do
    tables = tables + 1
    for key, fn in next, item.owner do
        if examined >= 20000 or scanned >= 33554432 then break end
        if type(key) == "string" and type(fn) == "function" and not seen[fn] then
            seen[fn] = true
            examined = examined + 1
            local ok, data = pcall(string.dump, fn)
            if ok and type(data) == "string" then
                scanned = scanned + #data
                local hit = false
                for _, needle in ipairs(needles) do
                    if data:find(needle, 1, true) then hit=true;break end
                end
                if hit and #data <= 131072 and emitted + #data <= 1048576 then
                    print("AQM-FUNCTION " .. item.name .. "." .. key .. " " .. #data)
                    for i=1,#data,128 do
                        local hex = data:sub(i,i+127):gsub(".", function(c)
                            return string.format("%02x",string.byte(c))
                        end)
                        print(hex)
                    end
                    print("AQM-END")
                    matched, emitted = matched + 1, emitted + #data
                elseif hit then
                    print("AQM-SKIPPED " .. item.name .. "." .. key .. " size-limit")
                end
            end
        end
    end
    if examined >= 20000 or scanned >= 33554432 then break end
end
print("AQM-SEARCH DONE functions=" .. examined .. " matches=" .. matched
    .. " scanned-bytes=" .. scanned .. " tables=" .. tables
    .. " limited=" .. tostring(examined >= 20000 or scanned >= 33554432))
