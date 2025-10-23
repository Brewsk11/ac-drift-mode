local RaycastUtils = require('drift-mode.RaycastUtils')

local Scorable = require("drift-mode.models.Elements.Scorables.Scorable")

local Common = require("drift-mode.models.Common.init")
local Point = Common.Point.Point
local Segment = Common.Segment.Segment
local PointArray = Common.Point.Array
local Arc = require("drift-mode.models.Common.Arc.Arc")
local Handle = require("drift-mode.models.Elements.Scorables.ZoneArc.Handle")


---@class ZoneArc : Scorable Class representing a drift scoring zone
---@field name string Name of the zone
---@field private arc Arc
---@field private _inside_arc Arc?
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
    self.width = width or 3

    self:setArc(arc)
    self:cacheMethod("getInsideArc")
    self:cacheMethod("gatherColliders")
    self:cacheMethod("gatherHandles")
    self:cacheMethod("getStartGate")
    self:cacheMethod("getCenter")
    self:cacheMethod("getBoundingBox")
end

function ZoneArc:setDirty()
    Scorable.setDirty(self)
    if self.arc then self.arc:setDirty() end
end

function ZoneArc:getArc()
    return self.arc
end

function ZoneArc:setArc(arc)
    self.arc = arc
    self:setDirty()
end

function ZoneArc:recalcArcFromTriplet(from, to, midpoint)
    self:getArc():recalcFromTriplet(from, to, midpoint)
    self:setDirty()
end

function ZoneArc:setWidth(width)
    self.width = width
    self:setDirty()
end

function ZoneArc:getInsideArc()
    local arc = self:getArc()
    if arc == nil then return nil end

    local inside_arc = Arc(
        arc:getCenter(),
        arc:getRadius() - self.width,
        arc:getNormal(),
        arc:getStartAngle(),
        arc:getSweepAngle()
    )
    return inside_arc
end

---@return physics.ColliderType[]
function ZoneArc:gatherColliders()
    if not self.collide then return {} end

    local colliders = {}

    for idx, segment in self:getArc():toPointArray(8):segment(false) do
        local parallel = (segment:getTail():value() - segment:getHead():value()):normalize()
        local look = parallel:clone():cross(vec3(0, 1, 0))
        local up = parallel:clone():cross(look)

        local collider = physics.Collider.Box(
            vec3(segment:lenght(), 1, 0.01),
            segment:getCenter():value() + vec3(0, 0.5),
            look,
            up,
            false
        )
        colliders[idx] = collider
    end

    return colliders
end

function ZoneArc:setCollide(value)
    self.collide = value
    self:setDirty()
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
---@param point Point
---@return boolean
function ZoneArc:isInZoneArc(point)
    local distance_to_center = point:value():distance(self.arc:getCenter():value())
    if distance_to_center > self.arc:getRadius() or
        distance_to_center < self.arc:getRadius() - self.width then
        return false
    end

    -- Grab the geometric data
    local center          = self.arc:getCenter()
    local normal          = self.arc:getNormal()
    local startAngle      = self.arc:getStartAngle()
    local sweepAngle      = self.arc:getSweepAngle()

    -- 1. Project the point onto the arc's plane
    local projected_point = projectToPlane(point, center, normal)

    -- 2. Vector from centre to projected point & its length
    local radial          = (projected_point:value() - center:value()):normalize() -- assumes vector subtraction

    -- 4. Build an orthonormal basis in the plane
    local u               = self.arc:getU() -- first basis vector
    local v               = self.arc:getV()

    -- 5. Signed angle between start direction and radial vector
    local alpha           = math.atan2(radial:dot(v), radial:dot(u)) -- in (-π,π]

    -- 6. Signed sweep test
    local delta           = alpha - startAngle
    if sweepAngle > 0 then
        if delta < 0 then delta = delta + 2 * math.pi end
        return delta >= 0 and delta <= sweepAngle
    else -- sweepAngle < 0
        if delta > 0 then delta = delta - 2 * math.pi end
        return delta <= 0 and delta >= sweepAngle
    end
end

---Return a segment that is the entry gate of the zone, ie. segment between first
---inside line point and first outside line point.
---@param self ZoneArc
---@return Segment?
function ZoneArc:getStartGate()
    if self:getArc() and self:getInsideArc() then
        return Segment(self:getArc():getStartPoint(), self:getInsideArc():getStartPoint())
    end
    return nil
end

---@return Point?
function ZoneArc:getCenter()
    if self:getArc() == nil then return end

    local dir = (self.arc:getStartDirection() + self.arc:getEndDirection()) / 2
    local dist = self.arc:getRadius() - self.width / 2
    local center = self.arc:getCenter()
    return Point(center:value() + dir * dist)
end

---Moves all zone points such that the passed point
---becomes the zones centroid (visual center).
---@param point Point
function ZoneArc:setZoneArcPosition(point)
    local center = self:getCenter()
    local offset = self:getArc():getCenter():value() - center:value()

    self:getArc():setCenter(Point(point:value() + offset))
    self:setDirty()
end

function ZoneArc:realignZoneArcPointOnTrack()
    --TODO: This is buggy when moving the midpoint handle
    -- don't do automatically, have a button for user to realign if needed instead.
    local arc = self:getArc()
    if arc == nil then return end

    local p1, p2, p3 = arc:getStartPoint(), arc:getEndPoint(), arc:getPointOnArc(0.5)
    RaycastUtils.alignPointToTrack(p1)
    RaycastUtils.alignPointToTrack(p2)
    RaycastUtils.alignPointToTrack(p3)

    if p1 == nil or p2 == nil or p3 == nil then
        return
    end

    local v1 = p1:value():sub(p2:value())
    local v2 = p3:value():sub(p2:value())
    local normal = v2:cross(v1):normalize()

    arc.normal = normal
    self:setDirty()
end

function ZoneArc:getBoundingBox()
    -- If there's no geometry, we cannot provide a bounding box
    if not self.arc then return nil end

    -- The zone arc is an annular sector bounded by the outer arc (`self.arc`)
    -- and the inner arc (`self._inside_arc`).  For simplicity we approximate
    -- the bounding box by sampling points along both arcs.
    local samples = 5 -- number of samples – enough for a smooth result

    -- Initial extreme values
    local pMin = vec3(math.huge, math.huge, math.huge)
    local pMax = vec3(-math.huge, -math.huge, -math.huge)

    -- Helper to update min/max from a point
    local function upd(point)
        local v = point:value()
        pMin = vec3(math.min(pMin.x, v.x), math.min(pMin.y, v.y), math.min(pMin.z, v.z))
        pMax = vec3(math.max(pMax.x, v.x), math.max(pMax.y, v.y), math.max(pMax.z, v.z))
    end

    -- Sample points on the outer arc
    for i = 0, samples do
        local t = i / samples
        upd(self.arc:getPointOnArc(t))
    end

    -- Sample points on the inner arc if it exists
    local inside = self:getInsideArc()
    if inside then
        for i = 0, samples do
            local t = i / samples
            upd(inside:getPointOnArc(t))
        end
    end

    return { p1 = Point(pMin), p2 = Point(pMax) }
end

function ZoneArc:isEmpty()
    return self.arc == nil or self.width == 0.0
end

function ZoneArc:drawFlat(coord_transformer, scale)
    if self:getArc() ~= nil then
        for _, seg in self:getArc():toPointArray(8):segment(false):iter() do
            local head_mapped = coord_transformer(seg:getHead())
            local tail_mapped = coord_transformer(seg:getTail())
            ui.drawLine(head_mapped, tail_mapped, rgbm.colors.white, 1 * scale)
        end
    end

    if self:getInsideArc() ~= nil then
        for _, seg in self:getInsideArc():toPointArray(8):segment(false):iter() do
            local head_mapped = coord_transformer(seg:getHead())
            local tail_mapped = coord_transformer(seg:getTail())
            ui.drawLine(head_mapped, tail_mapped, rgbm.colors.white, 0.5 * scale)
        end
    end
end

---@return { [HandleId] : ZoneArcHandle }
function ZoneArc:gatherHandles()
    local pois = {}
    local arc = self:getArc()

    local prefix = self:getId() .. "_"

    if arc ~= nil then
        pois[prefix .. Handle.Type.Center] = Handle(
            prefix .. Handle.Type.Center,
            self:getCenter(),
            self,
            Handle.Type.Center,
            Common.Point.Drawers.Simple()
        )

        pois[prefix .. Handle.Type.ArcStart] = Handle(
            prefix .. Handle.Type.ArcStart,
            arc:getStartPoint(),
            self,
            Handle.Type.ArcStart,
            Common.Point.Drawers.Simple()
        )

        pois[prefix .. Handle.Type.ArcEnd] = Handle(
            prefix .. Handle.Type.ArcEnd,
            arc:getEndPoint(),
            self,
            Handle.Type.ArcEnd,
            Common.Point.Drawers.Simple()
        )

        pois[prefix .. Handle.Type.ArcControl] = Handle(
            prefix .. Handle.Type.ArcControl,
            arc:getPointOnArc(0.35),
            self,
            Handle.Type.ArcControl,
            Common.Point.Drawers.Simple()
        )

        if self:getInsideArc() then
            pois[prefix .. Handle.Type.WidthHandle] = Handle(
                prefix .. Handle.Type.WidthHandle,
                self:getInsideArc():getPointOnArc(0.10),
                self,
                Handle.Type.WidthHandle,
                Common.Point.Drawers.Simple()
            )
        end
    end
    return pois
end

local Assert = require('drift-mode.Assert')
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
