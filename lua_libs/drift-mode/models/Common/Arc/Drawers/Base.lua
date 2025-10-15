local Drawer = require("drift-mode.models.Drawer")

---@class DrawerArc : Drawer
local DrawerArc = class("DrawerArc", Drawer)
DrawerArc.__model_path = "Common.Arc.Drawers.Base"

function DrawerArc:initialize()
end

function DrawerArc:getN(arc, maxDistance)
    if maxDistance == nil then
        maxDistance = 4
    end
    return math.min(math.ceil(arc:getDistance() / maxDistance), 64)
end

---@param arc Arc
function DrawerArc:draw(arc)
end

return DrawerArc
