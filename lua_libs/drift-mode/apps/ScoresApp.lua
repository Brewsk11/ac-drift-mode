local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/ui_layouts/scores')

local listener_id = EventSystem.registerListener('app-scores')

local ScoresApp = {}

---@type RunStateData?
local run_state_data = nil

---@type TrackConfig?
local track_data = nil

function ScoresApp.Main()
    run_state_data = DataBroker.read("run_state_data")

    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    appScoresLayout(run_state_data, track_data)
end

return ScoresApp
