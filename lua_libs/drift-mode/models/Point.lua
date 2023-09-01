local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Point : ClassBase Class representing a point in the world space
---@field private _value vec3 World coordinate position of the point on the track
---@field private _flat vec2
---@field private _projected vec3
local Point = class("Point")

---@param value vec3 World position
function Point:initialize(value)
    self:set(value)
end

function Point:serialize()
    local data = {
        __class = "Point",
        _value = S.serialize(self:value())
    }
    return data
end

function Point.deserialize(data)
    Assert.Equal(data.__class, "Point", "Tried to deserialize wrong class")
    return Point(S.deserialize(data._value))
end

---@private
function Point:generateVariants()
    self._flat = vec2(self:value().x, self:value().z)
    self._projected = vec3(self:value().x, 0, self:value().z)
end

---Set the point value
---@param self Point
---@param value vec3 New point position
function Point:set(value)
    self._value = value
    self:generateVariants()
end

---Return the point value
---@param self Point
---@return vec3
function Point:value()
    return self._value
end


---Return the track point as vec2, projecting it on Y axis
---@param self Point
---@return vec2
function Point:flat()
    return self._flat
end

---Return 2D projected track point in 3D world space
---@param self Point
---@return vec3
function Point:projected()
    return self._projected
end

function Point:draw(size, color)
    render.debugPoint(self:value(), size, color)
end

local function test()
    -- Point()
    local point = Point(vec3(1, 2, 3))
    assert(point:value() == vec3(1, 2, 3), tostring(point:value()) .. " vs. " .. tostring(vec3(1, 2, 3)))

    -- Point:value()
    -- Point:flat()
    -- Point:projected()
    local point = Point(vec3(1, 2, 3))
    assert(point:value() == vec3(1, 2, 3))
    assert(point:flat() == vec2(1, 3))
    assert(point:projected() == vec3(1, 0, 3))

    -- Point:set()
    point:set(vec3(4, 5, 6))
    assert(point:value() == vec3(4, 5, 6), tostring(point:value()) .. " vs. " .. tostring(vec3(4, 5, 6)))
end
test()

return Point
