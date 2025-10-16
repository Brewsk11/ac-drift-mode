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

    self:cacheMethod("toPointArray")
    self:cacheMethod("getPointOnArc")
end

---@param circle Circle
---@return Arc
function Arc.fromCircle(circle)
    return Arc(circle:getCenter(), circle:getRadius(), circle:getNormal())
end

---@param start_point Point
---@param end_point Point
---@param control_point Point?
function Arc:calculateAngles(start_point, end_point, control_point)
    local start_angle = self:getAngleForPoint(start_point)
    self.start_angle = start_angle

    local end_angle = self:getAngleForPoint(end_point)
    local control_point_angle = self:getAngleForPoint(control_point)

    local relative_end = (end_angle - start_angle + 2 * math.pi) % (2 * math.pi)
    local relative_control = (control_point_angle - start_angle + 2 * math.pi) % (2 * math.pi)
    if relative_control < relative_end then
        self.sweep_angle = relative_end
    else
        self.sweep_angle = relative_end - 2 * math.pi
    end
end

function Arc:recalcFromTriplet(from, to, midpoint)
    -- TODO: This one can probably be optimized not to create a new object
    local a = Arc.fromTriplet(from, to, midpoint)
    if a == nil then return end
    self._center = a:getCenter()
    self._radius = a:getRadius()
    self._normal = a:getNormal()
    self.start_angle = a:getStartAngle()
    self.sweep_angle = a:getSweepAngle()
    self:setDirty()
end

function Arc:getStartAngle()
    return self.start_angle
end

function Arc:getSweepAngle()
    return self.sweep_angle
end

function Arc:getDistance()
    return math.abs(2 * math.pi * self:getRadius() * self:getSweepAngle())
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

    return point_on_arc
end

function Arc:getStartPoint()
    return self:getPointOnArc(0.0)
end

function Arc:getEndPoint()
    return self:getPointOnArc(1.0)
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

    local arc = Arc.fromCircle(arc_circle)

    arc:calculateAngles(from, to, midpoint)

    return arc
end

function Arc:__tostring()
    return string.format("Arc[center=(%g, %g, %g), radius=%g, normal=(%g, %g, %g), start_angle=%g, sweep_angle=%g]",
        self._center:value().x, self._center:value().y, self._center:value().z, self._radius, self._normal.x,
        self._normal.y, self._normal.z, self.start_angle, self.sweep_angle)
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
