local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPointSphere : DrawerPoint
local DrawerPointSphere = class("DrawerPointSphere", DrawerPoint)

function DrawerPointSphere:initialize()
end

---@param point Point
function DrawerPointSphere:draw(point)
    render.debugSphere(point:value(), 1, rgbm(3, 0, 0, 3))
end

return DrawerClip
