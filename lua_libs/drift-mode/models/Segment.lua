local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local WorldObject = require('drift-mode/models/WorldObject')

---@class Segment : WorldObject Class representing a line (two connected points) in world space
---@field head Point World coordinate position of the point on the track
---@field tail Point World coordinate position of the point on the track
local Segment = class('Segment', WorldObject)

---@param head Point
---@param tail Point
function Segment:initialize(head, tail)
    self.head = head
    self.tail = tail
end

---Return 2-item array with start and end point values
---@param self Segment
---@return vec3 head, vec3 tail Start and end points of the segment
function Segment:get()
    return self.head:value(), self.tail:value()
end

---Return the track point as vec2, projecting it on Y axis
---@param self Segment
---@return vec2 head, vec2 tail and finish points of the flatten segment
function Segment:flat()
    return self.head:flat(), self.tail:flat()
end

---Return the track point as vec2, projecting it on Y axis
---@param self Segment
---@return vec3 head, vec3 tail Start and finish points of the projected segment
function Segment:projected()
    return self.head:projected(), self.tail:projected()
end

function Segment:lenght()
    return self.head:value():distance(self.tail:value())
end

function Segment:lengthFlat()
    return self.head:flat():distance(self.tail:flat())
end

function Segment:lenghtProjected()
    return self.head:projected():distance(self.tail:projected())
end

function Segment:getCenter()
    return Point((self.head:value() + self.tail:value()) / 2)
end

function Segment:getNormal()
    return Point(vec3():set(self.tail:value() - self.head:value()):cross(vec3(0, 1, 0)):normalize())
end

local function test()
    local points = {}
    points[1] = Point(vec3(1, 1, 1))
    points[2] = Point(vec3(2, 2, 2))

    local segment = Segment(points[1], points[2])

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
