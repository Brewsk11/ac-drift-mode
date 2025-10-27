local Resources = require('drift-mode.Resources')

local DrawerCourse = require("drift-mode.models.Elements.Course.Drawers.DrawerCourse")
local DrawerGateSimple = require('drift-mode.models.Elements.Gate.Drawers.Simple')

---@class DrawerCoursePlay : DrawerCourse
local DrawerCoursePlay = class("DrawerCourse", DrawerCourse)
DrawerCoursePlay.__model_path = "Elements.Course.Drawers.DrawerCoursePlay"

function DrawerCoursePlay:initialize()
    DrawerCourse.initialize(self)
    self.drawerStartLine = DrawerGateSimple(Resources.Colors.Start)
    self.drawerFinishLine = DrawerGateSimple(Resources.Colors.Finish)
    self.drawerRespawnLine = DrawerGateSimple(Resources.Colors.Respawn)
    self.drawerClip = nil
    self.drawerZone = nil
    self.drawerZoneArc = nil
    self.drawerStartingPoint = nil
end

---@param course TrackConfig
function DrawerCoursePlay:draw(course)
    render.setDepthMode(render.DepthMode.ReadOnly)

    DrawerCourse.draw(self, course)
end

return DrawerCoursePlay
