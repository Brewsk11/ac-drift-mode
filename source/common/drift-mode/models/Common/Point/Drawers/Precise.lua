local DrawerPoint = require("drift-mode.models.Common.Point.Drawers.Base")

---@class DrawerPointPrecise : DrawerPoint
local DrawerPointPrecise = class("DrawerPointPrecise", DrawerPoint)
DrawerPointPrecise.__model_path = "Common.Point.Drawers.Precise"

function DrawerPointPrecise:initialize(color, size)
    self.color = color or rgbm(1, 1, 1, 1)
    self.size = size or 0.2
end

---@param point Point
function DrawerPointPrecise:draw(point)
    render.debugCross(
        point:value(),
        self.size,
        self.color
    )
end

return DrawerPointPrecise
