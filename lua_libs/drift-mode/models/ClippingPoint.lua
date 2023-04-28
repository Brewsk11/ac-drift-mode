local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClippingPoint Class representing a drift scoring zone
---@field name string Name of the zone
---@field origin Point
---@field direction vec3
---@field length number
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run)
local ClippingPoint = {}
ClippingPoint.__index = ClippingPoint

local color_origin = rgbm(3, 0, 0, 1)
local color_pole = rgbm(0, 0, 3, 0.4)
local color_arrow = rgbm(0, 0, 3, 1)

function ClippingPoint.serialize(self)
    local data = {
        __class = "ClippingPoint",
        name = S.serialize(self.name),
        origin = self.origin:serialize(),
        direction = S.serialize(self.direction),
        length = S.serialize(self.length),
        maxPoints = S.serialize(self.maxPoints)
    }
    return data
end

function ClippingPoint.deserialize(data)
    Assert.Equal(data.__class, "ClippingPoint", "Tried to deserialize wrong class")

    local obj = ClippingPoint.new(
        S.deserialize(data.name),
        Point.deserialize(data.origin),
        S.deserialize(data.direction),
        S.deserialize(data.length),
        S.deserialize(data.maxPoints)
    )
    return obj
end

---@param name string
---@param origin Point
---@param direction vec3
---@param length number
---@param maxPoints integer
---@return ClippingPoint
function ClippingPoint.new(name, origin, direction, length, maxPoints)
    local self = setmetatable({}, ClippingPoint)
    self.name = name
    self.origin = origin
    self.direction = direction
    self.length = length
    self.maxPoints = maxPoints
    return self
end

function ClippingPoint.draw(self)
    self.origin:draw(0.6, color_origin)
    render.debugArrow(self.origin:value(), self.origin:value() + self.direction * self.length, 0.1, color_arrow)
    render.debugLine(self.origin:value(), self.origin:value() + vec3(0, 2, 0), color_pole)
    render.debugText(self.origin:value() + vec3(0, 2, 0), self.name)
end

local Assert = require('drift-mode/assert')
local function test()
end
test()

return ClippingPoint
