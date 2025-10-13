local ModelBase = require("drift-mode.models.ModelBase")
local Circle = require("drift-mode.models.Common.Circle")
local Point = require('drift-mode.models.Common.Point.Point')
local Assert = require("drift-mode.assert")
local PointArray = require("drift-mode.models.Common.Point.Array")

---@alias Angle number

---@class Arc : Circle
---@field private start_angle Angle
---@field private sweep_angle Angle
local Arc = class("Arc", Circle)
Arc.__model_path = "Common.Arc.Arc"


---@overload fun(self, circle, start_angle, sweep_angle) : Arc -- For emmy lua
---@overload fun(circle: Circle, start_angle: Angle, sweep_angle: Angle) : Arc
---@param center Point?
---@param radius number?
---@param normal vec3?
---@param start_angle Angle?
---@param sweep_angle Angle?
function Arc:initialize(center, radius, normal, start_angle, sweep_angle)
    Circle.initialize(self, center, radius, normal)

    self.start_angle = start_angle or 0
    self.sweep_angle = sweep_angle or 0
end

---@param circle Circle
---@param start_angle Angle?
---@param sweep_angle Angle?
---@return Arc
function Arc.fromCircle(circle, start_angle, sweep_angle)
    return Arc(circle:getCenter(), circle:getRadius(), circle:getNormal(), start_angle, sweep_angle)
end

---Used for Arc to be consistently defined.
---Use this vector and cross with the circle normal.
---This gives a consistent vector that is planar to the circle.
---Arc uses this vector to define the direction of 0 deg angle.
---@private
Arc._planarVecBase = vec3(1, 0, 0)

---@param self Arc|Circle
function Arc.getU(self)
    return self:getNormal():clone():cross(Arc._planarVecBase):normalize()
end

function Arc.getV(self)
    return self:getNormal():clone():cross(self:getU())
end

function Arc:getStartAngle()
    return self.start_angle
end

function Arc:getSweepAngle()
    return self.sweep_angle
end

function Arc:getStartDirection()
    return Circle._rotateVectorAroundAxis(self:getU(), self:getNormal(), self:getStartAngle())
end

function Arc:getEndDirection()
    return Circle._rotateVectorAroundAxis(self:getU(), self:getNormal(), self:getStartAngle() + self:getSweepAngle())
end

function Arc:getPointOnArc(t)
    local u = self:getU()
    local v = self:getV()

    local alpha = self:getStartAngle() + t * self:getSweepAngle()
    local point_on_arc = Point(self:getCenter():value() + (self:getRadius() * (math.cos(alpha) * u +
        math.sin(alpha) * v)))

    ac.log(point_on_arc)
    return point_on_arc
end

function Arc:getStartPoint()
    return self:getPointOnArc(1.0)
end

function Arc:getEndPoint()
    return self:getPointOnArc(0.0)
end

---@param n integer
---@return PointArray
function Arc:toPointArray(n)
    local points = PointArray()
    local t = 1 / n
    for i = 0, n do
        points:append(self:getPointOnArc(i * t))
    end

    return points
end

---@param from Point
---@param to Point
---@param midpoint Point
---@return Arc?
function Arc.fromTriplet(from, to, midpoint)
    local arc_circle = Circle.fromTriplet(from, to, midpoint)
    if arc_circle == nil then return nil end

    local base_planar = Arc.getU(arc_circle)

    local from_angle = base_planar:angle(from:value() - arc_circle:getCenter():value())
    local to_angle = base_planar:angle(to:value() - arc_circle:getCenter():value())

    return Arc.fromCircle(arc_circle, from_angle, to_angle)
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
