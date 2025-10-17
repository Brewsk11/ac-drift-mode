local ModelBase = require("drift-mode.models.ModelBase")
local Point = require('drift-mode.models.Common.Point.Point')
local PointArray = require("drift-mode.models.Common.Point.Array")


---@class Circle : ModelBase
---@field protected center Point
---@field protected radius number
---@field protected normal vec3
local Circle = class("Circle", ModelBase)
Circle.__model_path = "Common.Circle"

---@overload fun(self, center, radius, normal) : Circle -- For emmy lua
---@overload fun(center: Point?, radius: number?, normal: vec3?) : Circle
function Circle:initialize(center, radius, normal)
    ModelBase.initialize(self)

    self.center = center or Point(vec3(0, 0, 0))
    self.radius = radius or 0
    self.normal = normal or vec3(0, 1, 0)

    self.normal:normalize()
end

function Circle:setDirty()
    ModelBase.setDirty(self)
    if self.center then self.center:setDirty() end
end

---@return vec3
function Circle:getNormal()
    return self.normal
end

---@return Point
function Circle:getCenter()
    return self.center
end

function Circle:setCenter(value)
    self.center = value
    self:setDirty()
end

---@return number
function Circle:getRadius()
    return self.radius
end

---Used for circle (and arc) to be consistently defined.
---Use this vector and cross with the circle normal.
---This gives a consistent vector that is planar to the circle.
---Circle uses this vector to define the direction of 0 deg angle.
---@private
Circle._planarVecBase = vec3(1, 0, 0)

function Circle.getU(self)
    return self:getNormal():clone():cross(Circle._planarVecBase):normalize()
end

function Circle.getV(self)
    return self:getNormal():clone():cross(self:getU())
end

function Circle:getAngleForPoint(point)
    local vec_to_point = (point:value() - self:getCenter():value()):normalize()
    local local_x = vec_to_point:dot(self:getU())
    local local_y = vec_to_point:dot(self:getV())
    return math.atan2(local_y, local_x)
end

---@param vec vec3
---@param axis vec3
---@param alpha number
---@protected
---@return vec3
function Circle._rotateVectorAroundAxis(vec, axis, alpha)
    axis:normalize()
    local quatRot = quat.fromAngleAxis(alpha, axis)
    return vec:clone():rotate(quatRot)
end

---@param n integer
---@return PointArray
function Circle:toPointArray(n)
    local angle = 2 * math.pi / n
    local planar = self.normal:clone():cross(vec3(1, 0, 0))
    local points = PointArray()
    for i = 0, n - 1 do
        local v_from_center = Circle._rotateVectorAroundAxis(planar, self.normal, angle * i)
        local new_v = self.center:value() + v_from_center:normalize() * self.radius
        points:append(Point(new_v))
    end

    return points
end

local function vec3_len_sq(v)
    return v:dot(v)
end

-- Calculates the center and radius of the circle described by the arc's three points in 3D space.
-- The calculation is based on finding the intersection of three planes:
-- 1. The plane containing the three points.
-- 2. The perpendicular bisector plane of the segment p1-p2.
-- 3. The perpendicular bisector plane of the segment p2-p3.
-- This is solved by setting up and solving a 3x3 system of linear equations.
---@param p1 Point
---@param p2 Point
---@param p3 Point
---@return Circle?, string? err
function Circle.fromTriplet(p1, p2, p3)
    local v1 = p1:value()
    local v2 = p2:value()
    local v3 = p3:value()

    -- Define vectors from the points
    local v12 = v2:clone():sub(v1)
    local v13 = v3:clone():sub(v1)

    -- The normal to the plane containing the arc is the cross product of two vectors on that plane.
    local n_plane = v12:clone():cross(v13)

    -- If the magnitude of the normal is near zero, the points are collinear.
    if vec3_len_sq(n_plane) < 1e-12 then
        return nil, "The three points are collinear; a circle cannot be determined."
    end

    -- Normals to the perpendicular bisector planes are the vectors between the points.
    local n_bisect1 = v12
    local n_bisect2 = v3:clone():sub(v2)

    -- Midpoints of the segments
    local m1 = v1:clone():add(v12:clone():scale(0.5))
    local m2 = v2:clone():add(n_bisect2:clone():scale(0.5))

    -- Set up the system of linear equations Ax = b to find the center (x,y,z).
    -- The matrix A contains the normals of the three intersecting planes.
    local A = {
        { n_plane.x,   n_plane.y,   n_plane.z },
        { n_bisect1.x, n_bisect1.y, n_bisect1.z },
        { n_bisect2.x, n_bisect2.y, n_bisect2.z }
    }

    -- The vector b contains the dot product of each normal with a point on its plane.
    local b = {
        n_plane:clone():dot(v1),
        n_bisect1:clone():dot(m1),
        n_bisect2:clone():dot(m2)
    }

    -- Solve the system using Cramer's rule. First, find the determinant of A.
    local det_A = A[1][1] * (A[2][2] * A[3][3] - A[3][2] * A[2][3]) -
        A[1][2] * (A[2][1] * A[3][3] - A[3][1] * A[2][3]) +
        A[1][3] * (A[2][1] * A[3][2] - A[3][1] * A[2][2])

    if math.abs(det_A) < 1e-12 then
        -- This case should ideally not be reached if the collinearity check passes.
        return nil, "Failed to find a unique circle center (planes may be parallel)."
    end

    -- Find determinant of A with b replacing column x
    local det_Ax = b[1] * (A[2][2] * A[3][3] - A[3][2] * A[2][3]) -
        A[1][2] * (b[2] * A[3][3] - b[3] * A[2][3]) +
        A[1][3] * (b[2] * A[3][2] - b[3] * A[2][2])

    -- Find determinant of A with b replacing column y
    local det_Ay = A[1][1] * (b[2] * A[3][3] - b[3] * A[2][3]) -
        b[1] * (A[2][1] * A[3][3] - A[3][1] * A[2][3]) +
        A[1][3] * (A[2][1] * b[3] - A[3][1] * b[2])

    -- Find determinant of A with b replacing column z
    local det_Az = A[1][1] * (A[2][2] * b[3] - A[3][2] * b[2]) -
        A[1][2] * (A[2][1] * b[3] - A[3][1] * b[2]) +
        b[1] * (A[2][1] * A[3][2] - A[3][1] * A[2][2])

    local center = Point(vec3(
        det_Ax / det_A,
        det_Ay / det_A,
        det_Az / det_A
    ))

    -- The radius is the distance from the center to any of the arc's points.
    local radius = v1:clone():sub(center:value()):length()

    return Circle(center, radius, n_plane), nil
end

function Circle:__tostring()
    return string.format("Circle[center=(%g, %g, %g), radius=(%g, %g, %g), normal=(%g, %g, %g)]",
        self.center, self.radius, self.normal)
end

function Circle:drawDebug(mult)
    local _mult = mult or 1

    render.debugArrow(self.center:value(), self.center:value() + self.normal, 0.1, rgbm(0, 3, 0, 1))
    render.debugArrow(self.center:value(),
        self.center:value() + self.normal:clone():cross(vec3(1, 0, 0)):normalize() * self.radius, 0.1,
        rgbm(3, 0, 0, 1))

    -- self:toPointArray() would cause this call to route to Arc:toPointArray()
    -- if called from Arc:drawDebug()
    local segments = Circle.toPointArray(self, 36):segment(true)

    for _, seg in segments:iter() do
        render.debugLine(seg:getHead():value(), seg:getTail():value(), rgbm(3, 0, 0, 1) * _mult)
    end
end

function Circle.test()
end

return class.emmy(Circle, Circle.initialize)
