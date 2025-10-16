local DrawerSegment = require('drift-mode.models.Common.Segment.Drawers.Base')

---@class DrawerSegmentLine : DrawerSegment
---@field color rgbm
local DrawerSegmentLine = class("DrawerSegmentLine", DrawerSegment)
DrawerSegmentLine.__model_path = "Common.Segment.Drawers.Line"

function DrawerSegmentLine:initialize(color, label)
    DrawerSegment.initialize(self)
    self.color = color or rgbm(1, 1, 1, 3)
    self.label = label or ""
end

---@param segment Segment
function DrawerSegmentLine:draw(segment)
    DrawerSegment.draw(self, segment)

    render.debugLine(
        segment:getHead():value() + vec3(0, 0.05, 0),
        segment:getTail():value() + vec3(0, 0.05, 0),
        self.color
    )

    render.debugText(segment:getCenter():value() + vec3(0, 0.5, 0), self.label)
end

return DrawerSegmentLine
