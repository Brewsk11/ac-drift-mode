local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/ui_layouts/infobars')

local listener_id = EventSystem.registerListener('app-driftstatus')

local DriftStatusApp = {}

---@type RunStateData?
local run_state_data = nil

---@type TrackConfig?
local track_data = nil

function DriftStatusApp.Main()
    run_state_data = DataBroker.read("run_state_data")

    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    if run_state_data and track_data then
        drawModifiers(track_data.scoringRanges, run_state_data.driftState)
    end
end

return DriftStatusApp
