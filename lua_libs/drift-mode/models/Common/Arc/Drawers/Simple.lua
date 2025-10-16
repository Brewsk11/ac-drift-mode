local DrawerArc = require("drift-mode.models.Common.Arc.Drawers.Base")

---@class DrawerArcSimple : DrawerArc
local DrawerArcSimple = class("DrawerArcSimple", DrawerArc)
DrawerArcSimple.__model_path = "Common.Arc.Drawers.Simple"

function DrawerArcSimple:initialize(color)
    self.color = color or rgbm(1, 1, 1, 1)
end

---@param arc Arc
function DrawerArcSimple:draw(arc)
    if arc == nil then return end

    local seg_array = arc:toPointArray(self:getN(arc)):segment(false)
    for _, seg in seg_array:iter() do
        render.debugLine(seg:getHead():value(), seg:getTail():value())
    end
end

return DrawerArcSimple
