local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPoint : Drawer
local DrawerPoint = class("DrawerPoint", Drawer)

function DrawerPoint:initialize(color, size)
    self.color = color or rgbm(1, 1, 1, 1)
    self.size = size or 1
end

---@param point Point
function DrawerPoint:draw(point)
    render.debugSphere(
        point:value(),
        self.size,
        self.color
    )
end

return DrawerPoint
