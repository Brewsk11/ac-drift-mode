local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
require('drift-mode/models')


local map_ini_path = ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/data/map.ini"
local map_data = ac.INIConfig.load(map_ini_path)

local map_info = {
    offset = vec2(
        map_data:get('PARAMETERS', 'X_OFFSET', 0),
        map_data:get('PARAMETERS', 'Z_OFFSET', 0)),
    size = vec2(
        map_data:get('PARAMETERS', 'WIDTH', 1),
        map_data:get('PARAMETERS', 'HEIGHT', 1)),
    scale = map_data:get("PARAMETERS", "SCALE", 1)
}

---@type TrackConfig?
local track_data = nil


local CourseView = {}

local extra_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    extra_canvas:clear()
    extra_canvas:update(function(dt)
        local map_image_path = ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/map.png"

        if io.fileExists(map_image_path) then
            ui.drawImage(map_image_path, vec2(0, 0), map_info.size, ui.ImageFit.Fit)
        end

        ac.debug("map_info", map_info)

        local car_pos = Point(ac.getCar(0).position):flat()
        ac.debug("car_pos", car_pos)
        car_pos:add(map_info.offset)
        --:mul(map_info.size)
        --:div(vec2(map_info.size.x, map_info.size.x))
            :scale(map_info.scale)
        --:add(vec2(0, 20))

        ac.debug("car_pos2", car_pos)

        ui.drawCircleFilled(car_pos, 5, rgbm(0, 1, 0, 1))
        --track_data.scoringObjects[1]:getCenter()
    end)

    ui.drawImage(extra_canvas, vec2(0, 0), vec2(512, 512))

    ---@type TrackConfig?
    local track_data = nil
end

return CourseView
