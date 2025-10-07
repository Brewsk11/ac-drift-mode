local Drawer = require('drift-mode.models.Drawer')
local Zone = require("drift-mode.models.Elements.Scorables.Zone.Zone")
local Clip = require("drift-mode.models.Elements.Scorables.Clip.Clip")

---@class DrawerCourse : Drawer
---@field drawerStartLine DrawerSegment?
---@field drawerFinishLine DrawerSegment?
---@field drawerRespawnLine DrawerSegment?
---@field drawerClip DrawerClip?
---@field drawerZone DrawerZone?
---@field drawerStartingPoint DrawerStartingPoint?
local DrawerCourse = class("DrawerCourse", Drawer)
DrawerCourse.__model_path = "Elements.Course.Drawers.DrawerCourse"

function DrawerCourse:initialize()
end

---@param course TrackConfig
function DrawerCourse:draw(course)
    for _, obj in ipairs(course.scorables) do
        if obj.isInstanceOf(Zone) and self.drawerZone then
            self.drawerZone:draw(obj)
        elseif obj.isInstanceOf(Clip) and self.drawerClip then
            self.drawerClip:draw(obj)
        end
    end

    if course.startLine and self.drawerStartLine then
        self.drawerStartLine:draw(course.startLine)
    end

    if course.finishLine and self.drawerFinishLine then
        self.drawerFinishLine:draw(course.finishLine)
    end

    if course.respawnLine and self.drawerRespawnLine then
        self.drawerRespawnLine:draw(course.respawnLine)
    end

    if course.startingPoint and self.drawerStartingPoint then
        self.drawerStartingPoint:draw(course.startingPoint)
    end
end

return DrawerCourse
