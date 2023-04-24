---@class Point Class representing a point in the world space
---@field name string Name of the point
---@field position vec3 World coordinate position of the point on the track
local Point = {}
Point.__index = Point

---@param name string Point name
---@param position vec3 World poisition
---@return Point
function Point.new(name, position)
    local self = setmetatable({}, Point)
    self.name = name
    self.position = position
    return self
end

---Return the point value
---@param self Point
---@return vec3
function Point.get(self)
    return self.position
end

---Set the point value
---@param self Point
---@param value vec3 New point position
function Point.set(self, value)
    self.position = value
end

---Return the track point as vec2, projecting it on Y axis
---@param self Point
---@return vec2
function Point.flat(self)
    return vec2(self.position.x, self.position.z)
end

---Return 2D projected track point in 3D world space
---@param self Point
---@return vec3
function Point.projected(self)
    return vec3(self.position.x, 0, self.position.z)
end

local Assert = require('drift-mode/assert')
local function test()
    -- Point.new()
    local point = Point.new("point_test", vec3(1, 2, 3))
    assert(point.position == vec3(1, 2, 3), tostring(point.position) .. " vs. " .. tostring(vec3(1, 2, 3)))
    assert(point.name == "point_test", point.name .. " vs. " .. "point_test")

    -- Point:get()
    -- Point:flat()
    -- Point:projected()
    local point = Point.new("point_test", vec3(1, 2, 3))
    assert(point:get() == vec3(1, 2, 3))
    assert(point:flat() == vec2(1, 3))
    assert(point:projected() == vec3(1, 0, 3))

    -- Point:set()
    point:set(vec3(4, 5, 6))
    assert(point.position == vec3(4, 5, 6), tostring(point.position) .. " vs. " .. tostring(vec3(4, 5, 6)))
end
test()

return Point