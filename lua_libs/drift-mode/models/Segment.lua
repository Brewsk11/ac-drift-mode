local Assert = require('drift-mode/assert')

---@class Segment Class representing a line (two connected points) in world space
---@field head Point World coordinate position of the point on the track
---@field tail Point World coordinate position of the point on the track
local Segment = {}
Segment.__index = Segment

function Segment.serialize(self)
    local data = {
        __class = "Segment",
        head = self.head:serialize(),
        tail = self.tail:serialize()
    }
    return data
end

function Segment.deserialize(data)
    Assert.Equal(data.__class, "Segment", "Tried to deserialize wrong class")
    return Segment.new(
        Point.deserialize(data.head),
        Point.deserialize(data.tail))
end

---@param head Point Start of the segment
---@param tail Point End of the segment
---@return Segment
function Segment.new(head, tail)
    local self = setmetatable({}, Segment)
    self.head = head
    self.tail = tail
    return self
end

---Return 2-item array with start and end point values
---@param self Segment
---@return vec3 head, vec3 tail Start and end points of the segment
function Segment.get(self)
    return self.head:value(), self.tail:value()
end

---Return the track point as vec2, projecting it on Y axis
---@param self Segment
---@return vec2 head, vec2 tail and finish points of the flatten segment
function Segment.flat(self)
    return self.head:flat(), self.tail:flat()
end

---Return the track point as vec2, projecting it on Y axis
---@param self Segment
---@return vec3 head, vec3 tail Start and finish points of the projected segment
function Segment.projected(self)
    return self.head:projected(), self.tail:projected()
end

function Segment.draw(self, color)
    render.debugLine(self.head:value(), self.tail:value(), color)
end

function Segment.drawWall(self, color, height)
    render.quad(
        self.head:value(),
        self.tail:value(),
        self.tail:value() + vec3(0, height, 0),
        self.head:value() + vec3(0, height, 0),
        color
    )
end

local function test()
    local points = {}
    points[1] = Point.new("point_001", vec3(1, 1, 1))
    points[2] = Point.new("point_002", vec3(2, 2, 2))

    local segment = Segment.new(points[1], points[2])

    -- Segment:get()
    local a, b = segment:get()
    Assert.Equal(a, points[1]:value(), "Incorrect returned segment head")
    Assert.Equal(b, points[2]:value(), "Incorrect returned segment tail")

    -- Segment:flat()
    ---@diagnostic disable-next-line: cast-local-type
    a, b = segment:flat()
    Assert.Equal(a, points[1]:flat(), "Incorrect returned flat segment head")
    Assert.Equal(b, points[2]:flat(), "Incorrect returned flat segment tail")

    -- Segment:projected()
    a, b = segment:projected()
    Assert.Equal(a, points[1]:projected(), "Incorrect returned projected segment head")
    Assert.Equal(b, points[2]:projected(), "Incorrect returned projected segment tail")
end
test()

return Segment
