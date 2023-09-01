local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class StartingPoint : ClassBase
---@field origin Point
---@field direction vec3
local StartingPoint = class("StartingPoint")

---@param origin Point
---@param direction vec3
function StartingPoint:initialize(origin, direction)
    self.origin = origin
    self.direction = direction
end

function StartingPoint:serialize()
    local data = {
        __class = "StartingPoint",
        origin = self.origin:serialize(),
        direction = S.serialize(self.direction)
    }
    return data
end

function StartingPoint.deserialize(data)
    Assert.Equal(data.__class, "StartingPoint", "Tried to deserialize wrong class")

    local obj = StartingPoint(
        Point.deserialize(data.origin),
        S.deserialize(data.direction)
    )
    return obj
end

function StartingPoint:setEnd(new_end_point)
    self.direction = (new_end_point:value() - self.origin:value()):normalize()
end

function StartingPoint:drawSetup()
    self.origin:draw(0.6)
    render.debugArrow(self.origin:value(), self.origin:value() + self.direction, 0.1)
    render.debugLine(self.origin:value(), self.origin:value() + vec3(0, 2, 0))
    render.debugText(self.origin:value() + vec3(0, 2, 0), "Starting point")
end

local Assert = require('drift-mode/assert')
local function test()
end
test()

return StartingPoint
