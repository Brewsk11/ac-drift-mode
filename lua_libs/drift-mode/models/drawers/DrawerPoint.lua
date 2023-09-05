local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPoint : Drawer
local DrawerPoint = class("DrawerPoint", Drawer)

function DrawerPoint:initialize()
end

---@param point Point
function DrawerPoint:draw(point)
end

return DrawerClip
