local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
require('drift-mode/models')

local MapDisplayRenderer = require('drift-mode/MapDisplayRenderer')


---@type TrackConfig?
local track_data = nil

local app_map_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

local CourseView = {}


function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)

    app_map_canvas:clear()
    app_map_canvas:update(function(dt)
        MapDisplayRenderer.drawMapLayout(vec2(0, 0), vec2(512, 512))
        MapDisplayRenderer.drawCar(0, vec2(512, 512))
        if track_data then
            for idx, obj in ipairs(track_data.scoringObjects) do
                if obj:isInstanceOf(Zone) then
                    MapDisplayRenderer.drawZone(obj)
                elseif obj:isInstanceOf(Clip) then
                    MapDisplayRenderer.drawClip(obj)
                end
            end
        end
    end)

    ui.drawImage(app_map_canvas, vec2(0, 0), vec2(512, 512))
end

return CourseView
