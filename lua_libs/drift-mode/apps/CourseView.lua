local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
local MiniMapHelper3 = require('drift-mode/MiniMapHelper3')

require('drift-mode/models')

---@type TrackConfig?
local track_data = nil

local app_map_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

local CourseView = {}

---@type MinimapHelper
local minimap_helper = MiniMapHelper3(ac.getFolder(ac.FolderID.CurrentTrackLayout), vec2(512, 512))

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    local window_size = ui.windowSize()

    app_map_canvas:clear()
    app_map_canvas:update(function(dt)
        if track_data then
            if #track_data.scoringObjects == 0 then return end

            local bounding_box = track_data:getBoundingBox(10)

            minimap_helper.viewport_size = window_size

            minimap_helper:drawMap(vec2(0, 0), bounding_box)

            minimap_helper:drawTrackConfig(vec2(0, 0), track_data)

            minimap_helper:drawBoundingBox(vec2(0, 0))
            minimap_helper:drawCar(vec2(0, 0), 0)

            --ui.drawCircleFilled(minimap_helper:worldToBoundMap(Point(ac.getCar(0).position)), 3, rgbm(1, 0, 1, 1))
        end
    end)

    ui.drawImage(app_map_canvas, vec2(0, 0), vec2(512, 512))
end

return CourseView
