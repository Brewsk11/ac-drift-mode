local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/ui_layouts/infobars')

local listener_id = EventSystem.registerListener('app-driftstatus')

local DriftStatusApp = {}

-- EXPERIMENTAL: Use ac.connect() for drift ratio multiplier sharing
---@type DriftState
local drift_state = DriftState(0, 0, 0, 0)

local shared_data = ac.connect({
    ac.StructItem.key("driftmode__DriftState"),
    driftmode__drift_state_ratio = ac.StructItem.float()
})

---@type TrackConfig?
local track_data = nil

function DriftStatusApp.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    if drift_state and track_data then
        drift_state:calcDriftState(ac.getCar(0), track_data.scoringRanges)
        drift_state.ratio_mult = shared_data.driftmode__drift_state_ratio
        drawModifiers(track_data.scoringRanges, drift_state)
    end
end

return DriftStatusApp
