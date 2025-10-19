local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@class Point : ModelBase Class representing a point in the world space
---@field private _value vec3 World coordinate position of the point on the track
local Point = class("Point", ModelBase)
Point.__model_path = "Common.Point.Point"

---@param value vec3 World position
function Point:initialize(value)
    ModelBase.initialize(self)
    self:set(value)
    self:cacheMethod("flat")
    self:cacheMethod("projected")
end

function Point:__serialize()
    local S = require('drift-mode.serializer')
    local data = {
        _value = S.serialize(self:value()),
    }
    return data
end

function Point.__deserialize(data)
    local S = require('drift-mode.serializer')
    return Point(S.deserialize(data._value))
end

---Set the point value
---@param self Point
---@param value vec3 New point position
function Point:set(value)
    self._value = value
    self:setDirty()
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
    return vec2(self:value().x, self:value().z)
end

---Return 2D projected track point in 3D world space
---@param self Point
---@return vec3
function Point:projected()
    return vec3(self:value().x, 0, self:value().z)
end

function Point:draw(size, color)
    render.debugPoint(self:value(), size, color)
end

---@return Point
function Point:clone()
    return Point(self:value())
end

function Point:__tostring()
    return "Point" .. tostring(self:value())
end

function Point.test()
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

    -- Serialization
    local S = require('drift-mode.serializer')
    local pt = Point(vec3(1, 2, 3))
    local serialized = S.serialize(pt)
    local deserialized = S.deserialize(serialized)
    Assert.Equal(deserialized:flat(), vec2(1, 3))
end

return Point
