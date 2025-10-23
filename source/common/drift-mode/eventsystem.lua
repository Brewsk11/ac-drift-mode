local DataBroker = require('drift-mode.DataBroker')

---@class EventSystem
local EventSystem = class("EventSystem", ClassBase)

---@enum EventSystem.Signal
EventSystem.Signal = {
    CrossedFinish = "CrossedFinish",               ---Crossed finish line
    CrossedStart = "CrossedStart",                 ---Crossed start line
    CrossedRespawn = "CrossedRespawn",             ---Crossed respawn line
    TeleportToStart = "TeleportToStart",           ---Request to teleport to starting point
    ResetScore = "ResetScore",                     ---Requested run reset run scoring

    CursorChanged = "CursorChanged",               ---Signal for UI to update cursor data
    TrackConfigChanged = "TrackConfigChanged",     ---Signal for UI to update track data
    CarConfigChanged = "CarConfigChanged",         ---Signal for UI to update car data
    EditorsStateChanged = "EditorsStateChanged",   ---Signal for when car or track editor state changes

    ScorableStateChanged = "ScorableStateChanged", -- TODO: Document these
    ScorableStatesReset = "ScorableStatesReset",   -- TODO: Document these
}

function EventSystem:initialize()
    self.listeners = {}
    self.signal_log = ac.connect(self:createSignalLayout("signal_log"))
end

function EventSystem:createSignalLayout(listener_id)
    local layout = { ac.StructItem.key("drift-mode.events." .. listener_id) }
    for key, _ in pairs(EventSystem.Signal) do
        layout[key] = ac.StructItem.uint32()
    end

    return layout
end

local function storePayload(signal, payload)
    DataBroker.store("eventsystem_payload__" .. signal, payload)
end
local function loadPayload(signal)
    return DataBroker.read("eventsystem_payload__" .. signal) or {}
end

---@param listener_id string
function EventSystem:registerListener(listener_id)
    self.listeners[listener_id] = ac.connect(self:createSignalLayout(listener_id))
    return listener_id
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table|number|boolean|nil)
function EventSystem:listen(listener_id, signal, callback)
    local last_signal_id = self.signal_log[signal]
    local last_listeners_signal_id_read = self.listeners[listener_id][signal]

    if last_listeners_signal_id_read == last_signal_id then
        return false
    end

    local payload = loadPayload(signal)
    callback(payload)

    self.listeners[listener_id][signal] = last_signal_id
    return true
end

local UINT32_MAX = 4294967295

---@param signal EventSystem.Signal
---@param payload any
function EventSystem:emit(signal, payload)
    local emit_id = math.random(0, UINT32_MAX - 1)
    self.signal_log[signal] = emit_id
    storePayload(signal, payload)
end

return EventSystem()
