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

    DriftStateRatioChanged = "DriftStateMultChanged",
    ScoringObjectStateChanged = "ScoringObjectStateChanged", -- TODO: Document these
    ScoringObjectStatesReset = "ScoringObjectStatesReset",   -- TODO: Document these
}

local payloads = nil
local signal_log = nil

local signal_queue = {}
local listening = false

local function loadSignals()
    signal_log =
        DataBroker.read("signal_log") or
        {
            listeners = {},
            signals = {}
        }
end

local function loadPayloads()
    payloads = DataBroker.read("payloads") or {}
end

local function storeSignals() DataBroker.store("signal_log", signal_log) end
local function storePayloads() DataBroker.store("payloads", payloads) end

local charset = "abcdefghijklmnopqrstuvwxyz1234567890"
local function randomString(length)
    if length > 0 then
        local idx = math.random(1, #charset)
        return randomString(length - 1) .. charset:sub(idx, idx)
    else
        return ""
    end
end

---@param name string
function EventSystem.registerListener(name)
    loadSignals()

    signal_log.listeners[name] = {
        signals = {}
    }

    storeSignals()
    return name
end

local function unloadQueue()
    for idx, signal in ipairs(signal_queue) do
        EventSystem.emit(signal.signal, signal.payload)
        signal_queue[idx] = nil
    end
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table)
function EventSystem.listenInGroup(listener_id, signal, callback)
    listening = true

    local signal_data = signal_log.signals[signal]
    if signal_data == nil then return false end

    local changed = false

    local listener_signals_log = signal_log.listeners[listener_id].signals
    if listener_signals_log[signal] == nil then
        listener_signals_log[signal] = {
            last_responded = {
                id = nil
            }
        }
        changed = true
    end
    local listener_signal_log = listener_signals_log[signal]

    if listener_signal_log.last_responded.id ~= signal_data.last_sent.id then
        loadPayloads()
        callback(payloads[signal])
        listener_signal_log.last_responded = signal_data.last_sent
        changed = true
    end

    return changed
end

function EventSystem.startGroup()
    loadSignals()
end

function EventSystem.endGroup(changed)
    if changed then storeSignals() end
    listening = false
    unloadQueue()
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table|number|boolean|nil)
function EventSystem.listen(listener_id, signal, callback)
    EventSystem.startGroup()
    local changed = EventSystem.listenInGroup(listener_id, signal, callback)
    EventSystem.endGroup(changed)
end

---@param signal EventSystem.Signal
---@param payload any
function EventSystem.emit(signal, payload)
    loadPayloads()
    loadSignals()

    signal_log.signals[signal] = {
        last_sent = {
            id = randomString(8)
        }
    }
    payloads[signal] = payload

    storePayloads()
    storeSignals()
end

---Always use queue over emit when you want to emit a signal from within a listener
---@param signal any
---@param payload any
function EventSystem.queue(signal, payload)
    signal_queue[#signal_queue + 1] = { signal = signal, payload = payload }

    if not listening then
        unloadQueue()
    end
end

return EventSystem
