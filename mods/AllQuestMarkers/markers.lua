-- Own only handles created by our renderer. Never delete native map icons.
local M = {}
local function same(a, b)
    for _, k in ipairs({ "screen_x", "screen_y", "x", "y", "name", "category", "tracked" }) do
        if a[k] ~= b[k] then return false end
    end
    return true
end
function M.new(renderer, log)
    local self = { owned = {} }
    function self:clear()
        local success = true
        for k, entry in pairs(self.owned) do
            local ok, done = pcall(renderer.remove, entry.handle)
            if ok and done == true then self.owned[k] = nil
            else success = false; log("error", "remove failed: " .. k) end
        end
        return success
    end
    function self:sync(list)
        local wanted, success = {}, true
        for _, m in ipairs(list) do wanted[m.key] = m end
        for k, entry in pairs(self.owned) do
            local next_marker = wanted[k]
            if not next_marker or not same(entry.marker, next_marker) then
                local ok, done = pcall(renderer.remove, entry.handle)
                if ok and done == true then self.owned[k] = nil
                else success = false; log("error", "remove failed: " .. k) end
            end
        end
        for _, m in ipairs(list) do
            if not self.owned[m.key] then
                local ok, handle = pcall(renderer.create, m)
                if ok and handle ~= nil and handle ~= false then
                    self.owned[m.key] = { handle = handle, marker = m }
                    log("debug", "marker " .. m.key .. " world=" .. m.x .. "," .. m.y
                        .. " screen=" .. m.screen_x .. "," .. m.screen_y)
                else success = false; log("error", "create failed: " .. m.key) end
            end
        end
        return success
    end
    return self
end
return M
