local ModelBase = require("drift-mode.models.ModelBase")
local Circle = require("drift-mode.models.Common.Circle")
local Point = require('drift-mode.models.Common.Point.Point')
local Assert = require("drift-mode.assert")
local PointArray = require("drift-mode.models.Common.Point.Array")

---@alias Angle number

---@class Arc : Circle
---@field private _from_angle Angle
---@field private _to_angle Angle
local Arc = class("Arc", ModelBase)
Arc.__model_path = "Common.Arc"


---@overload fun(self, center, from_angle, to_angle) : Arc -- For emmy lua
---@overload fun(center: Circle, from_angle: Angle, to_angle: Angle) : Arc
---@param circle Circle
---@param from_angle Angle
---@param to_angle Angle
function Arc:initialize(circle, from_angle, to_angle)
    Circle.initialize(self, circle:getCenter(), circle:getRadius(), circle:getNormal())
    self._from_angle = from_angle
    self._to_angle = to_angle
end

---@param n integer
---@return PointArray
function Arc:toPointArray(n)
    local angle = (self._to_angle - self._from_angle) / n
    local normal = self._normal
    local radius = self._radius
    local center = self._center

    local planar = normal:clone():cross(vec3(1, 0, 0))
    planar = Circle._rotateVectorAroundAxis(planar, normal, self._from_angle)

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

function Arc.fromTriplet(from, to, midpoint)
    local arc_circle = Circle.fromTriplet(from, to, midpoint)
    local circle_normal = arc_circle:getNormal()
    local base_planar = circle_normal:clone():cross(Arc._planarVecBase)

    local from_angle = base_planar:angle(from)
    local to_angle = base_planar:angle(to)

    return Arc(arc_circle, from_angle, to_angle)
end

function Arc:drawDebug()
    Circle.drawDebug(self, 0.1)
    local segments = self:toPointArray(8):segment(false)

    for _, segment in segments:iter() do
        render.debugLine(segment.head:value(), segment.tail:value(), rgbm(0, 0, 3, 1))
    end
end

function Arc.test()
    local point1 = vec3(-1, 10, 3)
    local point2 = vec3(0, 12, 5)
    local point3 = vec3(1, 10, 5)

    local arc1 = Arc.fromTriplet(point1, point2, point3)

    local circle_data1 = arc1._circle

    if circle_data1 then
        print(string.format("Calculated Circle -> Center: (%g, %g, %g), Radius: %g, Normal: (%g, %g, %g)",
            circle_data1._center.x, circle_data1._center.y, circle_data1._center.z, circle_data1._radius,
            circle_data1._normal.x, circle_data1._normal.y, circle_data1._normal.z))
    end
end

return class.emmy(Arc, Arc.initialize)
