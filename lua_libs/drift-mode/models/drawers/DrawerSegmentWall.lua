local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerSegmentWall : DrawerSegment
---@field color rgbm
---@field height number
local DrawerSegmentWall = class("DrawerSegmentWall", DrawerSegment)

function DrawerSegmentWall:initialize(color, height)
    self.color = color or rgbm(1, 1, 1, 3)
    self.height = height or 1
end

---@param segment Segment
function DrawerSegmentWall.draw(self, segment)
    render.quad(
        segment.head:value(),
        segment.tail:value(),
        segment.tail:value() + vec3(0, self.height, 0),
        segment.head:value() + vec3(0, self.height, 0),
        self.color
    )
end

return DrawerSegmentWall
