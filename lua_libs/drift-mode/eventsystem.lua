local DataBroker = require('drift-mode/databroker')

local EventSystem = {}

---@enum EventSystem.Signal
EventSystem.Signal = {
    Finished = "Finished", ---Crossed finish line
    Started = "Started", ---Crossed start line
    Restart = "Restart", ---User requested game restart
}


local event_table = nil

local function loadEventTable()
    event_table = DataBroker.read("event_table")
    if event_table == nil then
        event_table = {
            listeners = {},
            signals = {}
        }
    end
end

local function storeEventTable()
    DataBroker.store("event_table", event_table)
end

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
    loadEventTable()

    event_table.listeners[name] = {
        signals = {}
    }

    storeEventTable()
    return name
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table)
function EventSystem.listen(listener_id, signal, callback)
    loadEventTable()

    local signal_data = event_table.signals[signal]
    if signal_data == nil then return end

    local listener_signals_log = event_table.listeners[listener_id].signals
    if listener_signals_log[signal] == nil then
        listener_signals_log[signal] = {
            last_responded = {
                id = nil,
                payload = nil
            }
        }
    end
    local listener_signal_log = listener_signals_log[signal]

    if listener_signal_log.last_responded.id ~= signal_data.last_sent.id then
        callback(signal_data.last_sent.payload)
        listener_signal_log.last_responded = signal_data.last_sent
        storeEventTable()
        return true
    end

    return false
end

---@param signal EventSystem.Signal
---@param payload table
function EventSystem.emit(signal, payload)
    event_table.signals[signal] = {
        last_sent = {
            id = randomString(8),
            payload = payload
        }
    }

    storeEventTable()
end

return EventSystem
