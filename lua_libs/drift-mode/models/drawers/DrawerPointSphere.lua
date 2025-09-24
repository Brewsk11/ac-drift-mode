local DrawerPoint = require("drift-mode.models.Drawers.DrawerPoint")

---@class DrawerPointSphere : DrawerPoint
local DrawerPointSphere = class("DrawerPointSphere", DrawerPoint)
DrawerPointSphere.__model_path = "Drawers.DrawerPointSphere"

function DrawerPointSphere:initialize(color, size)
    self.color = color or rgbm(1, 1, 1, 1)
    self.size = size or 1
end

---@param point Point
function DrawerPointSphere:draw(point)
    render.debugSphere(
        point:value(),
        self.size,
        self.color
    )
end

return DrawerPointSphere
