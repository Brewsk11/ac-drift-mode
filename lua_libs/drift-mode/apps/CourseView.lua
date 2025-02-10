local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
local MinimapHelper = require('drift-mode/MinimapHelper')

require('drift-mode/models')

---@type TrackConfig?
local track_data = nil

local app_map_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

local CourseView = {}

---@type MinimapHelper
local minimap_helper = MinimapHelper(ac.getFolder(ac.FolderID.CurrentTrackLayout))

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    local window_size = ui.windowSize()
    minimap_helper:setWidth(window_size.x)

    app_map_canvas:clear()
    app_map_canvas:update(function(dt)
        if track_data then
            if #track_data.scoringObjects == 0 then return end

            local bounding_box = track_data:getBoundingBox(20)
            minimap_helper:setBoundingBox(bounding_box)

            ui.drawImage(
                minimap_helper.track_map_image_path,
                vec2(0, 0),
                minimap_helper:getSize(),
                rgbm(1, 1, 1, 1),
                minimap_helper.uv1,
                minimap_helper.uv2)

            for _, obj in ipairs(track_data.scoringObjects) do
                obj:drawFlat(minimap_helper:worldToScaledBoundMapTransformer())
            end

            ui.drawRect(
                minimap_helper:worldToScaledBoundMap(bounding_box.p1),
                minimap_helper:worldToScaledBoundMap(bounding_box.p2),
                rgbm(1, 1, 0, 1))

            ui.drawCircleFilled(minimap_helper:worldToScaledBoundMap(Point(ac.getCar(0).position)), 3, rgbm(1, 0, 1, 1))
        end
    end)

    ui.drawImage(app_map_canvas, vec2(0, 0), vec2(512, 512))
end

return CourseView
