local DataBroker = require('drift-mode/databroker')

local EventSystem = {}

---@enum EventSystem.Signal
EventSystem.Signal = {
    CrossedFinish = "CrossedFinish",             ---Crossed finish line
    CrossedStart = "CrossedStart",               ---Crossed start line
    CrossedRespawn = "CrossedRespawn",           ---Crossed respawn line
    TeleportToStart = "TeleportToStart",         ---Request to teleport to starting point
    ResetScore = "ResetScore",                   ---Requested run reset run scoring

    CursorChanged = "CursorChanged",             ---Signal for UI to update cursor data
    TrackConfigChanged = "TrackConfigChanged",   ---Signal for UI to update track data
    CarConfigChanged = "CarConfigChanged",       ---Signal for UI to update car data
    EditorsStateChanged = "EditorsStateChanged", ---Signal for when car or track editor state changes

    DriftStateChanged = "DriftStateChanged",
    ScoringObjectStateChanged = "ScoringObjectStateChanged", -- TODO: Document these
    ScoringObjectStatesReset = "ScoringObjectStatesReset",   -- TODO: Document these
}

local charset = "abcdefghijklmnopqrstuvwxyz1234567890"
local function randomString(length)
    local result = {}
    for _ = 1, length do
        local idx = math.random(1, #charset)
        table.insert(result, charset:sub(idx, idx))
    end
    return table.concat(result)
end

local listeners = {}
local function storeListeners()
    DataBroker.store("eventsystem_listeners", listeners)
end
local function loadListeners()
    listeners = DataBroker.read("eventsystem_listeners") or {}
end

local signal_log = {}
local function storeSignalLog()
    DataBroker.store("eventsystem_signal_log", signal_log)
end
local function loadSignalLog()
    signal_log = DataBroker.read("eventsystem_signal_log") or {}
end

local function storePayload(signal, payload)
    DataBroker.store("eventsystem_payload__" .. signal, payload)
end
local function loadPayload(signal)
    return DataBroker.read("eventsystem_payload__" .. signal) or {}
end

---@param name string
function EventSystem.registerListener(name)
    loadListeners()
    listeners[name] = {
        signals_read = {}
    }
    storeListeners()
    return name
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table|number|boolean|nil)
function EventSystem.listen(listener_id, signal, callback)
    loadListeners()
    loadSignalLog()

    local last_signal_id = signal_log[signal]
    local last_listeners_signal_id_read = listeners[listener_id].signals_read[signal]

    ac.debug("last_listeners_signal_id_read", last_listeners_signal_id_read)
    ac.debug("last_signal_id", last_signal_id)
    if last_listeners_signal_id_read == last_signal_id then
        return false
    end

    local payload = loadPayload(signal)

    callback(payload)

    listeners[listener_id].signals_read[signal] = last_signal_id
    storeListeners()
    storeSignalLog()

    return true
end

---@param signal EventSystem.Signal
---@param payload any
function EventSystem.emit(signal, payload)
    loadSignalLog()

    local emit_id = randomString(8)
    signal_log[signal] = emit_id

    storeSignalLog()
    storePayload(signal, payload)
end

return EventSystem
