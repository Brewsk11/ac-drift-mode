local DrawerArc = require("drift-mode.models.Common.Arc.Drawers.Base")
local DrawerSegmentLine = require("drift-mode.models.Common.Segment.Drawers.Line")


---@class DrawerArcSetup : DrawerArc
local DrawerArcSetup = class("DrawerArcSetup", DrawerArc)
DrawerArcSetup.__model_path = "Common.Arc.Drawers.Setup"

function DrawerArcSetup:initialize(color)
    self.color = color or rgbm(1, 1, 1, 1)
    self.drawerSegment = DrawerSegmentLine(color)
end

---@param arc Arc
function DrawerArcSetup:draw(arc)
    if arc == nil then return end

    local seg_array = arc:toPointArray(self:getN(arc)):segment(false)
    for _, seg in seg_array:iter() do
        self.drawerSegment:draw(seg)
    end
end

return DrawerArcSetup
