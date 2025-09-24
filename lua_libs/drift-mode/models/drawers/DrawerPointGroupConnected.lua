local DrawerPointGroup = require('drift-mode/models/Drawers/DrawerPointGroup')

---@class DrawerPointGroupConnected : DrawerPointGroup
---@field drawerPoint DrawerPoint
---@field drawerSegment DrawerSegment
local DrawerPointGroupConnected = class("DrawerPointGroupConnected", DrawerPointGroup)
DrawerPointGroupConnected.__model_path = "Drawers.DrawerPointGroupConnected"

function DrawerPointGroupConnected:initialize(drawerSegment, drawerPoint)
    self.drawerSegment = drawerSegment
    self.drawerPoint = drawerPoint
end

---@param point_group PointGroup
function DrawerPointGroupConnected:draw(point_group)
    DrawerPointGroup.draw(self, point_group)

    if self.drawerSegment then
        for _, segment in point_group:segment(false):iter() do
            self.drawerSegment:draw(segment)
        end
    end
end

return DrawerPointGroupConnected
