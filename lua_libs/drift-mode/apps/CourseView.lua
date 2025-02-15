local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
local MinimapHelper = require('drift-mode/MinimapHelper')

require('drift-mode/models')

---@type TrackConfig?
local track_data = nil

---@type CarConfig?
local car_config = nil

---@type ScoringObjectStateData[]?
local scoring_object_state_data = nil

local app_map_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

local CourseView = {}

---@type MinimapHelper
local minimap_helper = MinimapHelper(ac.getFolder(ac.FolderID.CurrentTrackLayout), vec2(512, 512))

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.CarConfigChanged, function(payload)
        car_config = payload;
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStateAdded, function(payload)
        scoring_object_state_data[payload.idx] = payload.scoring_object_state;
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStatesReset, function(payload)
        scoring_object_state_data = payload;
    end)

    local window_size = ui.windowSize()

    app_map_canvas:clear()
    app_map_canvas:update(function(dt)
        if track_data then
            if #track_data.scoringObjects == 0 then return end

            local bounding_box = track_data:getBoundingBox(0)

            minimap_helper:setViewportSize(window_size)
            minimap_helper:setBoundingBox(bounding_box)

            minimap_helper:drawMap(vec2(0, 0))

            minimap_helper:drawTrackConfig(vec2(0, 0), track_data)

            -- minimap_helper:drawBoundingBox(vec2(0, 0))
            minimap_helper:drawCar(vec2(0, 0), 0, car_config)

            minimap_helper:drawRunState(vec2(0, 0), scoring_object_state_data)
        end
    end)

    ui.drawImage(app_map_canvas, vec2(0, 0), vec2(512, 512))
end

return CourseView
