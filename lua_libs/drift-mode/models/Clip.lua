local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Clip Class representing a drift scoring zone
---@field name string Name of the zone
---@field origin Point
---@field direction vec3
---@field length number
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run)
local Clip = {}
Clip.__index = Clip

local color_origin = rgbm(3, 0, 0, 1)
local color_pole = rgbm(0, 0, 3, 0.4)
local color_arrow = rgbm(0, 0, 3, 1)

function Clip.serialize(self)
    local data = {
        __class = "Clip",
        name = S.serialize(self.name),
        origin = self.origin:serialize(),
        direction = S.serialize(self.direction),
        length = S.serialize(self.length),
        maxPoints = S.serialize(self.maxPoints)
    }
    return data
end

function Clip.deserialize(data)
    -- 2.1.0 compatibility transfer
    if data.__class == "ClippingPoint" then data.__class = "Clip" end

    Assert.Equal(data.__class, "Clip", "Tried to deserialize wrong class")

    local obj = Clip.new(
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
---@return Clip
function Clip.new(name, origin, direction, length, maxPoints)
    local self = setmetatable({}, Clip)
    self.name = name
    self.origin = origin
    self.direction = direction
    self.length = length
    self.maxPoints = maxPoints
    return self
end

function Clip.drawSetup(self)
    self.origin:draw(0.6, color_origin)
    render.debugArrow(self.origin:value(), self.origin:value() + self.direction * self.length, 0.1, color_arrow)
    render.debugLine(self.origin:value(), self.origin:value() + vec3(0, 2, 0), color_pole)
    render.debugText(self.origin:value() + vec3(0, 2, 0), self.name)
end

local function test()
end
test()

return Clip
