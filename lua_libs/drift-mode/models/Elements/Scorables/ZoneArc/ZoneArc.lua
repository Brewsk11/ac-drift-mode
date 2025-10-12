local Assert = require('drift-mode.assert')
local RaycastUtils = require('drift-mode.RaycastUtils')

local Scorable = require("drift-mode.models.Elements.Scorables.Scorable")

local Common = require("drift-mode.models.Common.init")
local Point = Common.Point.Point
local Segment = Common.Segment.Segment
local PointArray = Common.Point.Array
local Arc = require("drift-mode.models.Common.Arc.Arc")

---@class ZoneArc : Scorable Class representing a drift scoring zone
---@field name string Name of the zone
---@field private arc Arc
---@field private width number
---@field private collide boolean Whether to enable colliders for this zone
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run)
local ZoneArc = class("ZoneArc", Scorable)
ZoneArc.__model_path = "Elements.Scorables.ZoneArc.ZoneArc"

---@param name string
---@param maxPoints integer
---@param collide boolean|nil
---@param arc Arc
---@param width number
function ZoneArc:initialize(name, maxPoints, collide, arc, width)
    Scorable.initialize(self, name, maxPoints)
    self.collide = collide or false
    self.arc = arc
    self.width = width
end

---@return physics.ColliderType[]
function ZoneArc:gatherColliders()
    -- NOT IMPLEMENTED: For now return nothing
    return {}
end

function ZoneArc:setCollide(value)
    self.collide = value
end

function ZoneArc:getCollide()
    return self.collide
end

--- Projects a point onto a plane.
--- @param point Point  The point to project.
--- @param on_plane Point The point on the plane (any point lying on the plane).
--- @param normal vec3 The plane normal (does not need to be normalised).
--- @return Point
local function projectToPlane(point, on_plane, normal)
    -- Ensure the normal is unit‑length
    local n = normal:normalize()
    -- Vector from plane centre to the point
    local v = point:value() - on_plane:value()
    -- Distance from the point to the plane along the normal
    local dist = v:dot(n)
    -- Subtract that distance along the normal to get the projection
    return Point(point:value() - n:scale(dist))
end

---Check if the point is inside the zone
---@param self ZoneArc
---@param point Point
---@return boolean
function ZoneArc:isInZoneArc(point)
    local distance_to_center = point:flat():distance(self.arc:getCenter():flat())
    if distance_to_center > self.arc:getRadius() or
        distance_to_center < self.arc:getRadius() - self.width then
        return false
    end

    local start_direction = self.arc:getStartDirection()
    local point_projected_on_arc_plane = projectToPlane(point, self.arc:getCenter(), self.arc:getNormal())
    local angle_between = start_direction:angle(point_projected_on_arc_plane:value())
    if angle_between > self.arc:getStartAngle() and
        angle_between < self.arc:getEndAngle() then
        return true
    end

    return false
end

---Check if a segment is inside the zone. Relatively expensive to compute.
---
---Naively assumes there's only one intersection. If both segment end-points are either in
---or out it assumes the whole segment is in or out.
---@param self ZoneArc
---@param segment Segment
---@param custom_origin Point? Custom origin point, to check corretly it must be outside the zone
---@return number fraction Fraction of the segment inside the zone: `1.0` fully inside, `0.0` fully outside
function ZoneArc:isSegmentInZoneArc(segment, custom_origin)
    -- NOT IMPLEMENTED
    return 0.0
end

---Return a segment that is the entry gate of the zone, ie. segment between first
---inside line point and first outside line point.
---@param self ZoneArc
---@return Segment?
function ZoneArc:getStartGate()
    -- NOT IMPLEMENTED
    return nil
end

function ZoneArc:getCenter()
    local dir = (self.arc:getStartDirection() - self.arc:getEndDirection()) / 2
    local dist = self.arc:getRadius() - self.width / 2
    local center = self.arc:getCenter()
    return Point(center:value() + dir * dist)
end

---Moves all zone points such that the passed point
---becomes the zones centroid (visual center).
---@param point Point
function ZoneArc:setZoneArcPosition(point)
    -- NOT IMPLEMENTED
end

function ZoneArc:realignZoneArcPointOnTrack()
    -- NOT IMPLEMENTED
end

function ZoneArc:getBoundingBox()
    -- NOT IMPLEMENTED
    return nil
end

function ZoneArc:isEmpty()
    return self.arc == nil or self.width == 0.0
end

function ZoneArc:drawFlat(coord_transformer, scale)
    -- NOT IMPLEMENTED
end

local Assert = require('drift-mode.assert')
local function test()
    -- projectToPlane()
    local normal = vec3(0, 1, 0)
    local p = Point(vec3(10, 20, -5))
    local p_on_plane = Point(vec3(9999, 10, -9999))
    local res = projectToPlane(p, p_on_plane, normal)
    Assert.Equal(res:value(), vec3(10, 10, -5))
end
test()

return class.emmy(ZoneArc, ZoneArc.initialize)
