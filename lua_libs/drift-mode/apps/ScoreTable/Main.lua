local DataBroker = require('drift-mode.databroker')
local EventSystem = require('drift-mode.eventsystem')
local ScoresLayout = require('drift-mode.ui_layouts.scores')

local listener_id = EventSystem:registerListener('app-scoretable')

local ScoresApp = {}

---@type ScorableState[]?
local scoring_object_states = nil

---@type TrackConfig?
local track_data = nil

function ScoresApp.Main(dt)
    EventSystem:listen(listener_id, EventSystem.Signal.ScorableStateChanged, function(payload)
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

    EventSystem:listen(listener_id, EventSystem.Signal.ScorableStatesReset, function(payload)
        ---@cast payload ScorableState[]
        scoring_object_states = payload
    end)

    EventSystem:listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        ---@cast payload TrackConfig
        track_data = payload;
    end)

    if track_data == nil then return end

    if scoring_object_states then
        ScoresLayout.appScoresLayout(scoring_object_states, track_data)
    end
end

return ScoresApp
