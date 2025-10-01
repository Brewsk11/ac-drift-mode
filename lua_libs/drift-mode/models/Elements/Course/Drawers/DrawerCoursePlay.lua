local Resources = require('drift-mode.Resources')

local DrawerCourse = require("drift-mode.models.Elements.Course.Drawers.DrawerCourse")
local DrawerSegmentLine = require('drift-mode.models.Drawers.DrawerSegmentLine')

---@class DrawerCoursePlay : DrawerCourse
local DrawerCoursePlay = class("DrawerCourse", DrawerCourse)
DrawerCoursePlay.__model_path = "Elements.Course.Drawers.DrawerCoursePlay"

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
