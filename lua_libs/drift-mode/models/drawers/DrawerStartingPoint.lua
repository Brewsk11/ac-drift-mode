local Drawer = require('drift-mode/models/Drawers/Drawer')

---@class DrawerStartingPoint : Drawer
local DrawerStartingPoint = class("DrawerStartingPoint", Drawer)
DrawerStartingPoint.__model_path = "Drawers.DrawerStartingPoint"

function DrawerStartingPoint:initialize()
end

---@param startingPoint StartingPoint
function DrawerStartingPoint:draw(startingPoint)

end

return DrawerStartingPoint
