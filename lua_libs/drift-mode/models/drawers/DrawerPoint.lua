local Drawer = require("drift-mode.models.Drawers.Drawer")

---@class DrawerPoint : Drawer
local DrawerPoint = class("DrawerPoint", Drawer)
DrawerPoint.__model_path = "Drawers.DrawerPoint"

function DrawerPoint:initialize()
end

---@param point Point
function DrawerPoint:draw(point)
end

return DrawerPoint
