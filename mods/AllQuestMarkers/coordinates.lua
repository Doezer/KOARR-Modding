-- Delegate projection to a verified host implementation on EVERY map view refresh.
local M = {}
local function finite(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end
function M.project(markers, adapter, view)
    local out = {}
    for _, m in ipairs(markers) do
        local ok, p = pcall(adapter.project, m, view)
        if not ok then return nil, "projection failed for " .. m.key end
        if p ~= nil then -- nil means outside the current viewport
            if type(p) ~= "table" or not finite(p.x) or not finite(p.y) then
                return nil, "invalid projected position for " .. m.key
            end
            local copy = {}
            for k, v in pairs(m) do copy[k] = v end
            copy.screen_x, copy.screen_y = p.x, p.y
            out[#out + 1] = copy
        end
    end
    return out
end
return M
