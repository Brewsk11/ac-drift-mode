local DataBroker = require('drift-mode.databroker')
local EventSystem = require('drift-mode.eventsystem')
local DriftState = require("drift-mode.models.Misc.DriftState")

require('drift-mode.ui_layouts.infobars')

local listener_id = EventSystem:registerListener('app-driftstatus')

local DriftStatusApp = {}

---@type DriftState
local drift_state = DriftState()

---@type TrackConfig?
local track_data = nil

function DriftStatusApp.Main(dt)
    EventSystem:listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    if drift_state and track_data then
        drawModifiers(track_data.scoringRanges, drift_state)
    end
end

return DriftStatusApp
