local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
require('drift-mode/models')


---@type TrackConfig?
local track_data = nil


local CourseView = {}

local extra_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    --if ui.button("Click") and track_data then
    extra_canvas:clear()
    extra_canvas:update(function(dt)
        local map_image_path = ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/map.png"
        local map_ini_path = ac.getFolder(ac.FolderID.CurrentTrackLayout .. "/data/map.ini")

        if io.fileExists(map_image_path) then
            ui.drawImage(map_image_path, vec2(0, 0), vec2(512, 512), ui.ImageFit.Fit)
        end

        local map_data = ac.INIConfig.load(map_ini_path)

        local map_info = {
            offset = vec2(
                map_data:get('PARAMETERS', 'Z_OFFSET', 0),
                map_data:get('PARAMETERS', 'X_OFFSET', 0)),
            size = vec2(
                map_data:get('PARAMETERS', 'WIDTH', 1),
                map_data:get('PARAMETERS', 'HEIGHT', 1))
        }

        local car_pos = Point(ac.getCar(0).position):flat()
        ac.debug("car_pos", car_pos)
        car_pos:add(vec2(178.491, 145.883))
            :mul(vec2(512, 512))
            :div(vec2(365.919, 365.919))

        ac.debug("car_pos2", car_pos)

        ui.drawCircleFilled(car_pos, 5, rgbm(0, 1, 0, 1))
        --track_data.scoringObjects[1]:getCenter()
    end)
    --end

    ---@type TrackConfig?
    local track_data = nil
end

return CourseView
