local Assert = require('drift-mode.assert')

local Point = require('drift-mode.models.Common.Point.Point')
local ModelBase = require("drift-mode.models.ModelBase")


---@class Segment : ModelBase Class representing a line (two connected points) in world space
---@field private head Point World coordinate position of the point on the track
---@field private tail Point World coordinate position of the point on the track
local Segment = class('Segment', ModelBase)
Segment.__model_path = "Common.Segment.Segment"

---@param head Point
---@param tail Point
function Segment:initialize(head, tail)
    ModelBase.initialize(self)
    self.head = head
    self.tail = tail

    self:cacheMethod("getCenter")
end

function Segment:registerDefaultObservers()
    if self.head then self.head:registerObserver(self) end
    if self.tail then self.tail:registerObserver(self) end
end

---Return 2-item array with start and end point values
---@param self Segment
---@return Point head, Point tail Start and end points of the segment
function Segment:get()
    return self.head, self.tail
end

---@return Point
function Segment:getHead()
    return self.head
end

---@return Point
function Segment:getTail()
    return self.tail
end

function Segment:set(head, tail)
    self:setHead(head)
    self:setTail(tail)
end

function Segment:setHead(point)
    self.head = point
    if self.head then
        self.head:registerObserver(self, function()
            self:setDirty()
        end)
    end
    self:setDirty()
end

function Segment:setTail(value)
    self.tail = value
    if self.tail then
        self.tail:registerObserver(self, function()
            self:setDirty()
        end)
    end
    self:setDirty()
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

function Segment:getDirection()
    return (self.tail:value() - self.head:value()):normalize()
end

function Segment:getNormal()
    return Point(vec3():set(self.tail:value() - self.head:value()):cross(vec3(0, 1, 0)):normalize())
end

---Move segment such that its center is at `point`
function Segment:moveTo(point)
    local lenght = self:lenght()
    local direction = self:getDirection()
    self.head:set(point:value() - direction * lenght / 2)
    self.tail:set(point:value() + direction * lenght / 2)
    self:setDirty()
end

function Segment:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawLine(coord_transformer(self.head), coord_transformer(self.tail), color, scale)
end

local function test()
    local points = {}
    points[1] = Point(vec3(1, 1, 1))
    points[2] = Point(vec3(2, 2, 2))

    local segment = Segment(points[1], points[2])

    -- Segment:get()
    local a, b = segment:get()
    Assert.Equal(a:value(), points[1]:value(), "Incorrect returned segment head")
    Assert.Equal(b:value(), points[2]:value(), "Incorrect returned segment tail")
end
test()

return Segment
