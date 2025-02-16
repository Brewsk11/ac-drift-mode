local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/ui_layouts/scores')

local listener_id = EventSystem.registerListener('app-scores')

local ScoresApp = {}

---@type DriftState?
local drift_state = nil

---@type ScoringObjectStateData[]?
local scoring_objects_state_data = nil

---@type TrackConfig?
local track_data = nil

function ScoresApp.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.DriftStateChanged, function(payload)
        drift_state = payload
    end)

    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStateChanged, function(payload)
        if scoring_objects_state_data == nil then return end
        if payload.type == "ZoneState" then
            scoring_objects_state_data[payload.idx].score_points[#scoring_objects_state_data[payload.idx].score_points + 1] =
                payload.scoring_object_state_delta;
        else
            scoring_objects_state_data[payload.idx] = payload.scoring_object_state;
        end
    end)

    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStatesReset, function(payload)
        scoring_objects_state_data = payload
    end)

    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    if track_data == nil then return end

    appScoresLayout(drift_state, scoring_objects_state_data, track_data)
end

return ScoresApp
