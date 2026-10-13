-- Adapter methods below belong to this project, NOT to the Amalur engine.
local M = {}
local events = { "map_open", "map_close", "map_view_changed", "quests_changed", "save_loaded", "region_changed" }
function M.new(adapter, modules, config, log)
    for _, k in ipairs({ "snapshot", "map_state", "project", "subscribe" }) do
        if type(adapter[k]) ~= "function" then return nil, "missing adapter method: " .. k end
    end
    if type(adapter.renderer) ~= "table" or type(adapter.renderer.create) ~= "function"
        or type(adapter.renderer.remove) ~= "function" then return nil, "missing renderer" end
    local self = { running = false, stopping = false, busy = false, dirty = false, unsubscribers = {}, session = nil, region = nil }
    self.markers = modules.markers.new(adapter.renderer, log)
    function self:refresh()
        if not self.running or self.stopping then return false end
        if self.busy then self.dirty = true; return true end
        self.busy = true
        local ok, result = pcall(function()
            -- Reentrant events get at most one extra pass; no unbounded frame polling.
            local success = true
            for pass = 1, 2 do
                self.dirty = false
                local view = adapter.map_state()
                if type(view) ~= "table" or view.open ~= true or config.enabled ~= true then
                    success = self.markers:clear(); break
                end
                local snapshot = adapter.snapshot()
                local selected, err = modules.objectives.select(snapshot, config)
                if not selected then error(err) end
                if snapshot.session ~= self.session or snapshot.region ~= self.region then
                    if not self.markers:clear() then return false end
                    self.session, self.region = snapshot.session, snapshot.region
                end
                local projected, why = modules.coordinates.project(selected, adapter, view)
                if not projected then error(why) end
                success = self.markers:sync(projected) and success
                if not self.dirty then break end
            end
            return success
        end)
        self.busy = false
        if not ok then
            log("error", "refresh failed; clearing overlay: " .. tostring(result))
            self.markers:clear()
            return false
        end
        return result
    end
    function self:stop()
        self.stopping = true
        local success = true
        for i = #self.unsubscribers, 1, -1 do
            local ok, done = pcall(self.unsubscribers[i])
            if ok and done == true then table.remove(self.unsubscribers, i)
            else success = false; log("error", "listener cleanup failed") end
        end
        success = self.markers:clear() and success
        if success then self.running = false; self.stopping = false end
        return success
    end
    function self:start()
        if self.stopping then return false, "cleanup pending" end
        if self.running then return true end
        self.running = true
        for _, event in ipairs(events) do
            local name = event
            local ok, unsubscribe = pcall(adapter.subscribe, name, function()
                if not self.running or self.stopping then return end
                if name == "map_close" then self.markers:clear()
                elseif name == "save_loaded" or name == "region_changed" then
                    if self.markers:clear() then self.session, self.region = nil, nil; self:refresh() end
                else self:refresh() end
            end)
            if not ok or type(unsubscribe) ~= "function" then
                self:stop()
                return false, "subscription failed: " .. name
            end
            self.unsubscribers[#self.unsubscribers + 1] = unsubscribe
        end
        local ready = self:refresh()
        if not ready then self:stop(); return false, "initial refresh failed" end
        return true
    end
    return self
end
return M
