local ModelBase = require("drift-mode.models.ModelBase")
local Circle = require("drift-mode.models.Common.Circle")
local Point = require('drift-mode.models.Common.Point.Point')
local Assert = require("drift-mode.assert")
local PointArray = require("drift-mode.models.Common.Point.Array")

---@alias Angle number

---@class Arc : Circle
---@field private _start_angle Angle
---@field private _end_angle Angle
local Arc = class("Arc", Circle)
Arc.__model_path = "Common.Arc.Arc"


---@overload fun(self, circle, start_angle, end_angle) : Arc -- For emmy lua
---@overload fun(circle: Circle, start_angle: Angle, end_angle: Angle) : Arc
---@param circle Circle
---@param start_angle Angle
---@param end_angle Angle
function Arc:initialize(circle, start_angle, end_angle)
    Circle.initialize(self, circle)

    self._start_angle = start_angle
    self._end_angle = end_angle
end

---@param n integer
---@return PointArray
function Arc:toPointArray(n)
    local angle = (self._end_angle - self._start_angle) / n
    local normal = self._normal
    local radius = self._radius
    local center = self._center

    local planar = normal:clone():cross(vec3(1, 0, 0))
    planar = Circle._rotateVectorAroundAxis(planar, normal, self._start_angle)

    local points = PointArray()
    for i = 0, n do
        local v_from_center = Circle._rotateVectorAroundAxis(planar, normal, angle * i)
        local new_v = center:value() + v_from_center:normalize() * radius
        points:append(Point(new_v))
    end

    return points
end

---Used for Arc to be consistently defined.
---Use this vector and cross with the circle normal.
---This gives a consistent vector that is planar to the circle.
---Arc uses this vector to define the direction of 0 deg angle.
---@private
Arc._planarVecBase = vec3(1, 0, 0)

---@private
function Arc:getPlanar()
    return self:getNormal():clone():cross(Arc._planarVecBase):normalize()
end

---@param from Point
---@param to Point
---@param midpoint Point
---@return Arc?
function Arc.fromTriplet(from, to, midpoint)
    local arc_circle = Circle.fromTriplet(from, to, midpoint)
    if arc_circle == nil then return nil end

    local normal = arc_circle:getNormal()
    local base_planar = normal:clone():cross(Arc._planarVecBase):normalize()

    local from_angle = base_planar:angle(from:value())
    local to_angle = base_planar:angle(to:value())

    return Arc(arc_circle, from_angle, to_angle)
end

function Arc:getStartAngle()
    return self._start_angle
end

function Arc:getEndAngle()
    return self._end_angle
end

function Arc:getStartDirection()
    return Circle._rotateVectorAroundAxis(self:getPlanar(), self:getNormal(), self._start_angle)
end

function Arc:getEndDirection()
    return Circle._rotateVectorAroundAxis(self:getPlanar(), self:getNormal(), self._end_angle)
end

function Arc:getStartPoint()
    return Point(self:getCenter() + self:getStartDirection() * self:getRadius())
end

function Arc:getEndPoint()
    return Point(self:getCenter() + self:getEndDirection() * self:getRadius())
end

function Arc:drawDebug()
    Circle.drawDebug(self, 0.1)
    local segments = self:toPointArray(8):segment(false)

    for _, segment in segments:iter() do
        render.debugLine(segment.head:value(), segment.tail:value(), rgbm(0, 0, 3, 1))
    end
end

function Arc.test()
    -- local point1 = Point(vec3(-1, 10, 3))
    -- local point2 = Point(vec3(0, 12, 5))
    -- local point3 = Point(vec3(1, 10, 5))

    -- local arc1 = Arc.fromTriplet(point1, point2, point3)

    -- if arc1 then
    --     print(string.format("Calculated Circle -> Center: (%g, %g, %g), Radius: %g, Normal: (%g, %g, %g)",
    --         arc1._center.x, arc1._center.y, arc1._center.z, arc1._radius,
    --         arc1._normal.x, arc1._normal.y, arc1._normal.z))
    -- end
end

return class.emmy(Arc, Arc.initialize)
