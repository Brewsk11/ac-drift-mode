local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerCoursePlay : DrawerCourse
local DrawerCoursePlay = class("DrawerCourse", DrawerCourse)

function DrawerCoursePlay:initialize()
    DrawerCourse.initialize(self)
    self.drawerStartLine = DrawerSegmentLine(rgbm(0.5, 3, 1, 3))
    self.drawerFinishLine = DrawerSegmentLine(rgbm(0.5, 1, 3, 3))
    self.drawerRespawnLine = DrawerSegmentLine(rgbm(3, 0.5, 1, 3))
    self.drawerClip = nil
    self.drawerZone = nil
    self.drawerStartingPoint = nil
end

---@param course TrackConfig
function DrawerCoursePlay:draw(course)
    DrawerCourse.draw(self, course)
end

return DrawerCoursePlay
