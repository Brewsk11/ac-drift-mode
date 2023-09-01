local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerSegmentLine : DrawerSegment
---@field color rgbm
local DrawerSegmentLine = class("DrawerSegmentLine", DrawerSegment)

function DrawerSegmentLine:initialize(color, label)
    DrawerSegment.initialize(self)
    self.color = color or rgbm(1, 1, 1, 3)
    self.label = label
end

---@param segment Segment
function DrawerSegmentLine:draw(segment)
    DrawerSegment.draw(self, segment)

    render.debugLine(
        segment.head:value() + vec3(0, 0.05, 0),
        segment.tail:value() + vec3(0, 0.05, 0),
        self.color
    )
    render.debugText(segment:getCenter() + vec3(0, 0.5, 0), self.label)
end

return DrawerSegmentLine
