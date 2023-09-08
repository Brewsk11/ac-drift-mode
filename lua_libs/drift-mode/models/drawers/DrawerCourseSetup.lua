local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerCourseSetup : DrawerCourse
local DrawerCourseSetup = class("DrawerCourse", DrawerCourse)

function DrawerCourseSetup:initialize()
    DrawerCourse.initialize(self)
    self.drawerStartLine = DrawerSegmentLine(rgbm(0.5, 3, 1, 3), "Start line")
    self.drawerFinishLine = DrawerSegmentLine(rgbm(0.5, 1, 3, 3), "Finish line")
    self.drawerRespawnLine = DrawerSegmentLine(rgbm(3, 0.5, 1, 3), "Respawn line")
    self.drawerClip = DrawerClipSetup()
    self.drawerZone = DrawerZoneSetup()
    self.drawerStartingPoint = DrawerStartingPointSetup()
end

---@param course TrackConfig
function DrawerCourseSetup:draw(course)
    DrawerCourse.draw(self, course)
end

return DrawerCourseSetup
