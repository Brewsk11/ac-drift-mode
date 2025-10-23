local Drawer = require("drift-mode.models.Drawer")

---@class DrawerPointArray : Drawer
---@field drawerPoint DrawerPoint
local DrawerPointArray = class("DrawerPointGroup", Drawer)
DrawerPointArray.__model_path = "Common.Point.Drawers.BaseArray"

function DrawerPointArray:initialize()
end

---@param point_array PointArray
function DrawerPointArray:draw(point_array)
    if self.drawerPoint then
        for _, point in point_array:iter() do
            self.drawerPoint:draw(point)
        end
    end
end

return DrawerPointArray
