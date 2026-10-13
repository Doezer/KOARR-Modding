local M = {}
function M.new(sink, debug)
    sink = sink or print
    return function(level, message)
        if level ~= "debug" or debug then
            -- One string: the framework's print replacement only accepts strings.
            pcall(sink, "[AllQuestMarkers][" .. level .. "] " .. tostring(message))
        end
    end
end
return M
