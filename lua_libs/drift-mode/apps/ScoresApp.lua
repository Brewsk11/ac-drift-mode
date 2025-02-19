local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/ui_layouts/scores')

local listener_id = EventSystem.registerListener('app-scores')

local ScoresApp = {}

---@type ScoringObjectState[]?
local scoring_object_states = nil

---@type TrackConfig?
local track_data = nil

function ScoresApp.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStateChanged, function(payload)
        if scoring_object_states == nil then return end
        for idx, obj in ipairs(scoring_object_states) do
            if obj:getName() == payload.name then
                if obj:updatesFully() then
                    scoring_object_states[idx] = payload.payload
                else
                    obj:consumeUpdate(payload.payload)
                end
                break
            end
        end
    end)

    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStatesReset, function(payload)
        scoring_object_states = payload
    end)

    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    if track_data == nil then return end

    if scoring_object_states then
        appScoresLayout(scoring_object_states, track_data)
    end
end

return ScoresApp
