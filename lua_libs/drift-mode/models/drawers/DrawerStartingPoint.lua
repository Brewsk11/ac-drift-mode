local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerStartingPoint : Drawer
local DrawerStartingPoint = class("DrawerStartingPoint", Drawer)

function DrawerStartingPoint:initialize()
end

---@param startingPoint StartingPoint
function DrawerStartingPoint:draw(startingPoint)

end

return DrawerStartingPoint
