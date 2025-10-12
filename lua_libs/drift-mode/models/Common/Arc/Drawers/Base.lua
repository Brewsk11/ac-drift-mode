local Drawer = require("drift-mode.models.Drawer")

---@class DrawerArc : Drawer
local DrawerArc = class("DrawerArc", Drawer)
DrawerArc.__model_path = "Common.Arc.Drawers.Base"

function DrawerArc:initialize()
end

---@param arc Arc
function DrawerArc:draw(arc)
end

return DrawerArc
