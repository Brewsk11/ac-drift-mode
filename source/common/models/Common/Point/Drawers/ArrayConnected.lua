local DrawerPointArray = require('drift-mode.models.Common.Point.Drawers.BaseArray')

---@class DrawerPointArrayConnected : DrawerPointArray
---@field drawerPoint DrawerPoint
---@field drawerSegment DrawerSegment
local DrawerPointArrayConnected = class("DrawerPointArrayConnected", DrawerPointArray)
DrawerPointArrayConnected.__model_path = "Common.Point.Drawers.ArrayConnected"

function DrawerPointArrayConnected:initialize(drawerSegment, drawerPoint)
    self.drawerSegment = drawerSegment
    self.drawerPoint = drawerPoint
end

---@param point_array PointArray
function DrawerPointArrayConnected:draw(point_array)
    DrawerPointArray.draw(self, point_array)

    if self.drawerSegment then
        for _, segment in point_array:segment(false):iter() do
            self.drawerSegment:draw(segment)
        end
    end
end

return DrawerPointArrayConnected
