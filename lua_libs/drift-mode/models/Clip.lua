local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Clip : ScoringObject Class representing a drift scoring zone
---@field name string Name of the zone
---@field origin Point
---@field direction vec3
---@field length number
---@field maxPoints integer Maximum points possible to score for the clip (in a perfect run)
---@field private lastPoint Point To calculate where crossed
local Clip = class("Clip", ScoringObject)

---@param name string
---@param origin Point
---@param direction vec3
---@param length number
---@param maxPoints integer
function Clip:initialize(name, origin, direction, length, maxPoints)
    self.name = name
    self.origin = origin
    self.direction = direction
    self.length = length
    self.maxPoints = maxPoints
end

function Clip.deserialize(data)
    -- 2.1.0 compatibility transfer
    if data.__class == "ClippingPoint" then data.__class = "Clip" end

    Assert.Equal(data.__class, "Clip", "Tried to deserialize wrong class")

    local obj = Clip(
        S.deserialize(data.name),
        Point.deserialize(data.origin),
        S.deserialize(data.direction),
        S.deserialize(data.length),
        S.deserialize(data.maxPoints)
    )
    return obj
end

function Clip:getEnd()
    return Point(self.origin:value() + self.direction * self.length)
end

function Clip:setEnd(new_end_point)
  self.direction = (new_end_point:value() - self.origin:value()):normalize()
  self.length = new_end_point:value():distance(self.origin:value())
end

local function test()
end
test()

return Clip
