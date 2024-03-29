local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPointSphere : DrawerPoint
local DrawerPointSphere = class("DrawerPointSphere", DrawerPoint)

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
