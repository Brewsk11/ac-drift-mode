local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Point Class representing a point in the world space
---@field name string Name of the point
---@field private _value vec3 World coordinate position of the point on the track
---@field private _flat vec2
---@field private _projected vec3
local Point = {}
Point.__index = Point

function Point.serialize(self)
    local data = {
        __class = "Point",
        name = S.serialize(self.name),
        _value = S.serialize(self:value())
    }
    return data
end

function Point.deserialize(data)
    Assert.Equal(data.__class, "Point", "Tried to deserialize wrong class")
    return Point.new(
        S.deserialize(data.name),
        S.deserialize(data._value))
end

---@param name string Point name
---@param value vec3 World poisition
---@return Point
function Point.new(name, value)
    local self = setmetatable({}, Point)
    self.name = name
    self:set(value)
    return self
end

---@private
function Point.generateVariants(self)
    self._flat = vec2(self:value().x, self:value().z)
    self._projected = vec3(self:value().x, 0, self:value().z)
end

---Set the point value
---@param self Point
---@param value vec3 New point position
function Point.set(self, value)
    self._value = value
    self:generateVariants()
end

---Return the point value
---@param self Point
---@return vec3
function Point.value(self)
    return self._value
end


---Return the track point as vec2, projecting it on Y axis
---@param self Point
---@return vec2
function Point.flat(self)
    return self._flat
end

---Return 2D projected track point in 3D world space
---@param self Point
---@return vec3
function Point.projected(self)
    return self._projected
end

function Point.draw(self, size, color)
    render.debugPoint(self:value(), size, color)
end

local function test()
    -- Point.new()
    local point = Point.new("point_test", vec3(1, 2, 3))
    assert(point:value() == vec3(1, 2, 3), tostring(point:value()) .. " vs. " .. tostring(vec3(1, 2, 3)))
    assert(point.name == "point_test", point.name .. " vs. " .. "point_test")

    -- Point:value()
    -- Point:flat()
    -- Point:projected()
    local point = Point.new("point_test", vec3(1, 2, 3))
    assert(point:value() == vec3(1, 2, 3))
    assert(point:flat() == vec2(1, 3))
    assert(point:projected() == vec3(1, 0, 3))

    -- Point:set()
    point:set(vec3(4, 5, 6))
    assert(point:value() == vec3(4, 5, 6), tostring(point:value()) .. " vs. " .. tostring(vec3(4, 5, 6)))
end
test()

return Point