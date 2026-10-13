-- Console entry point. It does NOT install guessed hooks or change game objects.
local base = "mods/AllQuestMarkers/"
local function load(name) return assert(loadfile(base .. name .. ".lua"))() end
local M = { version = "0.1.0-probe", status = "game-adapter-unverified" }
local config = load("config")
assert(type(config) == "table" and type(config.enabled) == "boolean"
    and type(config.categories) == "table" and type(config.max_markers) == "number"
    and config.max_markers >= 1 and config.max_markers <= 10000
    and config.max_markers == math.floor(config.max_markers), "invalid AllQuestMarkers config")
local log = load("log").new(print, config.debug)
M.probe = load("probe")
local modules = { objectives = load("objectives"), coordinates = load("coordinates"), markers = load("markers") }
local controller = load("controller")
local instance
function M.attach(adapter)
    if instance then return false, "detach existing instance before attaching" end
    local candidate, err = controller.new(adapter, modules, config, log)
    if not candidate then return false, err end
    -- Keep a reference even after partial startup so failed cleanup is retryable.
    instance = candidate
    local ok, why = instance:start()
    if not ok then return false, why end
    return true
end
function M.detach()
    if instance and not instance:stop() then return false, "cleanup pending; retry detach" end
    instance = nil
    return true
end
function M.refresh() return instance and instance:refresh() or false end
function M.set_enabled(value)
    if type(value) ~= "boolean" then return false, "enabled must be boolean" end
    config.enabled = value
    return not instance or instance:refresh()
end
log("info", "probe/core loaded; no verified game adapter, no markers or hooks installed")
return M
