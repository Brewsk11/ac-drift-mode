local Drawer = require('drift-mode.models.Drawer')

---@class DrawerGate : Drawer
local DrawerGate = class("DrawerGate", Drawer)
DrawerGate.__model_path = "Elements.Gate.Drawers.Base"

function DrawerGate:initialize()
end

---@param gate Gate
function DrawerGate:draw(gate)

end

return DrawerGate
