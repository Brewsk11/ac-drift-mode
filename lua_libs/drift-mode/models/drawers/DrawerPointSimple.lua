local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPointSimple : DrawerPoint
local DrawerPointSimple = class("DrawerPointSimple", DrawerPoint)

function DrawerPointSimple:initialize(color, size)
    self.color = color or rgbm(1, 1, 1, 1)
    self.size = size or 1
end

---@param point Point
function DrawerPointSimple:draw(point)
    render.debugPoint(
        point:value(),
        self.size,
        self.color
    )
end

return DrawerPointSimple
