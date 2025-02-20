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

local charset = "abcdefghijklmnopqrstuvwxyz1234567890"
local function randomString(length)
    local result = {}
    for _ = 1, length do
        local idx = math.random(1, #charset)
        table.insert(result, charset:sub(idx, idx))
    end
    return table.concat(result)
end

---@param name string
function EventSystem.registerListener(name)
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table)
function EventSystem.listenInGroup(listener_id, signal, callback)
end

---@param listener_id string
---@param signal EventSystem.Signal
---@param callback fun(payload: table|number|boolean|nil)
function EventSystem.listen(listener_id, signal, callback)

end

---@param signal EventSystem.Signal
---@param payload any
function EventSystem.emit(signal, payload)

end

return EventSystem
