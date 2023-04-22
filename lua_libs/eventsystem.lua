local json = require('drift-mode/json')
local Serializer = require('drift-mode/serializer')
local DataBroker = require('drift-mode/databroker')

local EventSystem = {}

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

function EventSystem.registerListener(name)
    loadEventTable()

    event_table.listeners[name] = {
        signals = {}
    }

    storeEventTable()
    return name
end

function EventSystem.listen(listener_id, signal_name)
    loadEventTable()

    local signal_data = event_table.signals[signal_name]
    if signal_data == nil then return end

    local listener_signals_log = event_table.listeners[listener_id].signals
    if listener_signals_log[signal_name] == nil then
        listener_signals_log[signal_name] = {
            last_responded = {
                id = nil,
                payload = nil
            }
        }
    end
    local listener_signal_log = listener_signals_log[signal_name]

    local changed = false
    local payload = nil
    if listener_signal_log.last_responded.id ~= signal_data.last_sent.id then
        payload = signal_data.last_sent.payload
        listener_signal_log.last_responded = signal_data.last_sent
        changed = true
        storeEventTable()
    end

    return changed, payload
end

function EventSystem.emit(signal_name, payload)
    event_table.signals[signal_name] = {
        last_sent = {
            id = randomString(8),
            payload = payload
        }
    }

    storeEventTable()
end

return EventSystem
