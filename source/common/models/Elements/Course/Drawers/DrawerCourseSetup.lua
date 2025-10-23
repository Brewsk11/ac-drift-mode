local DrawerCourse = require('drift-mode.models.Elements.Course.Drawers.DrawerCourse')
local DrawerGateSetup = require('drift-mode.models.Elements.Gate.Drawers.Setup')
local DrawerClipSetup = require('drift-mode.models.Elements.Scorables.Clip.Drawers.Clip.Setup')
local DrawerZoneSetup = require('drift-mode.models.Elements.Scorables.Zone.Drawers.Zone.Setup')
local DrawerZoneArcSetup = require('drift-mode.models.Elements.Scorables.ZoneArc.Drawers.ZoneArc.Setup')
local DrawerPositionSetup = require('drift-mode.models.Elements.Position.Drawers.Setup')

---@class DrawerCourseSetup : DrawerCourse
local DrawerCourseSetup = class("DrawerCourse", DrawerCourse)
DrawerCourseSetup.__model_path = "Elements.Course.Drawers.DrawerCourseSetup"

function DrawerCourseSetup:initialize()
    DrawerCourse.initialize(self)
    self.drawerStartLine = DrawerGateSetup(rgbm(0.5, 3, 1, 3))
    self.drawerFinishLine = DrawerGateSetup(rgbm(0.5, 1, 3, 3))
    self.drawerRespawnLine = DrawerGateSetup(rgbm(3, 0.5, 1, 3))
    self.drawerClip = DrawerClipSetup()
    self.drawerZone = DrawerZoneSetup()
    self.drawerZoneArc = DrawerZoneArcSetup()
    self.drawerStartingPoint = DrawerPositionSetup()
end

---@param course TrackConfig
function DrawerCourseSetup:draw(course)
    render.setDepthMode(render.DepthMode.ReadOnly)

    DrawerCourse.draw(self, course)
end

return DrawerCourseSetup
