local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')
local Resources = require('drift-mode/Resources')

---@class DrawerCoursePlay : DrawerCourse
local DrawerCoursePlay = class("DrawerCourse", DrawerCourse)
DrawerCoursePlay.__model_path = "Drawers.DrawerCoursePlay"

function DrawerCoursePlay:initialize()
    DrawerCourse.initialize(self)
    self.drawerStartLine = DrawerSegmentLine(Resources.Colors.Start)
    self.drawerFinishLine = DrawerSegmentLine(Resources.Colors.Finish)
    self.drawerRespawnLine = DrawerSegmentLine(Resources.Colors.Respawn)
    self.drawerClip = nil
    self.drawerZone = nil
    self.drawerStartingPoint = nil
end

---@param course TrackConfig
function DrawerCoursePlay:draw(course)
    render.setDepthMode(render.DepthMode.ReadOnly)

    DrawerCourse.draw(self, course)
end

return DrawerCoursePlay
