local Drawer = require('drift-mode.models.Drawer')

---@class DrawerPosition : Drawer
local DrawerPosition = class("DrawerPosition", Drawer)
DrawerPosition.__model_path = "Elements.Position.Drawers.Base"

function DrawerPosition:initialize()
end

---@param startingPoint Position
function DrawerPosition:draw(startingPoint)

end

return DrawerPosition
