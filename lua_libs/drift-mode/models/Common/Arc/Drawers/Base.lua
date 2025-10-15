local Drawer = require("drift-mode.models.Drawer")

---@class DrawerArc : Drawer
local DrawerArc = class("DrawerArc", Drawer)
DrawerArc.__model_path = "Common.Arc.Drawers.Base"

function DrawerArc:initialize()
end

function DrawerArc:getN(arc, maxDistance)
    if maxDistance == nil then
        maxDistance = 10
    end

    local maxN = 16
    local res = math.min(math.ceil(arc:getDistance() / maxDistance), maxN)

    return res
end

---@param arc Arc
function DrawerArc:draw(arc)
end

return DrawerArc
