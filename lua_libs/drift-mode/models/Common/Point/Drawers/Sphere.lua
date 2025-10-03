local DrawerPoint = require("drift-mode.models.Common.Point.Drawers.Base")

---@class DrawerPointSphere : DrawerPoint
local DrawerPointSphere = class("DrawerPointSphere", DrawerPoint)
DrawerPointSphere.__model_path = "Common.Point.Drawers.Sphere"

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
