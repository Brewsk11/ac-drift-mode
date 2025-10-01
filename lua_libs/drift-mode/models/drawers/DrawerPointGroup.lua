local Drawer = require("drift-mode.models.Drawer")

---@class DrawerPointGroup : Drawer
---@field drawerPoint DrawerPoint
local DrawerPointGroup = class("DrawerPointGroup", Drawer)
DrawerPointGroup.__model_path = "Drawers.DrawerPointGroup"

function DrawerPointGroup:initialize()
end

---@param point_group PointGroup
function DrawerPointGroup:draw(point_group)
    if self.drawerPoint then
        for _, point in point_group:iter() do
            self.drawerPoint:draw(point)
        end
    end
end

return DrawerPointGroup
