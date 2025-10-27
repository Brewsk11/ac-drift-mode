local DrawerArc = require("drift-mode.models.Common.Arc.Drawers.Base")
local DrawerSegmentWall = require("drift-mode.models.Common.Segment.Drawers.Wall")


---@class DrawerArcSimple : DrawerArc
local DrawerArcSimple = class("DrawerArcSimple", DrawerArc)
DrawerArcSimple.__model_path = "Common.Arc.Drawers.Simple"

function DrawerArcSimple:initialize(color, height)
    self.color = color or rgbm(1, 1, 1, 1)
    self.height = 1 or height
    self.drawerSegment = DrawerSegmentWall(color, height)
end

---@param arc Arc
function DrawerArcSimple:draw(arc)
    if arc == nil then return end

    local seg_array = arc:toPointArray(self:getN(arc)):segment(false)
    for _, seg in seg_array:iter() do
        self.drawerSegment:draw(seg)
    end
end

return DrawerArcSimple
