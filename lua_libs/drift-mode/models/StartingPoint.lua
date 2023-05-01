local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class StartingPoint
---@field origin Point
---@field direction vec3
local StartingPoint = {}
StartingPoint.__index = StartingPoint

function StartingPoint.serialize(self)
    local data = {
        __class = "StartingPoint",
        origin = self.origin:serialize(),
        direction = S.serialize(self.direction)
    }
    return data
end

function StartingPoint.deserialize(data)
    Assert.Equal(data.__class, "StartingPoint", "Tried to deserialize wrong class")

    local obj = StartingPoint.new(
        Point.deserialize(data.origin),
        S.deserialize(data.direction)
    )
    return obj
end

---@param origin Point
---@param direction vec3
---@return StartingPoint
function StartingPoint.new(origin, direction)
    local self = setmetatable({}, StartingPoint)
    self.origin = origin
    self.direction = direction
    return self
end

function StartingPoint.drawSetup(self)
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
