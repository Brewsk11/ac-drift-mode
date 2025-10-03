local Assert = require('drift-mode.assert')
local RaycastUtils = require('drift-mode.RaycastUtils')
local Resources = require('drift-mode.Resources')

local Point = require("drift-mode.models.Common.Point.Point")
local Segment = require("drift-mode.models.Common.Segment.Segment")
local ScoringObject = require("drift-mode.models.Elements.Scorables.ScoringObject")
local PointGroup = require("drift-mode.models.Common.Point.PointGroup")

---@class Zone : ScoringObject Class representing a drift scoring zone
---@field name string Name of the zone
---@field private outsideLine PointGroup Outside zone line definition
---@field private insideLine PointGroup Inside zone line definition
---@field private polygon PointGroup Polygon created from inside and outside lines
---@field private collide boolean Whether to enable colliders for this zone
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run)
local Zone = class("Zone", ScoringObject)
Zone.__model_path = "Elements.Scorables.Zone.Zone"

---@param name string
---@param outsideLine PointGroup|nil
---@param insideLine PointGroup|nil
---@param maxPoints integer
---@param collide boolean|nil
function Zone:initialize(name, outsideLine, insideLine, maxPoints, collide)
    self.name = name
    self.maxPoints = maxPoints
    self.collide = collide or false
    self.outsideLine = outsideLine or PointGroup()
    self.insideLine = insideLine or PointGroup()
    self:setDirty()
end

function Zone:__serialize()
    -- Custom serializer prevents redundant self.polygon serialization
    local S = require('drift-mode.serializer')
    return {
        name = S.serialize(self.name),
        maxPoints = S.serialize(self.maxPoints),
        collide = S.serialize(self.collide),
        outsideLine = S.serialize(self.outsideLine),
        insideLine = S.serialize(self.insideLine)
    }
end

function Zone.__deserialize(data)
    local S = require('drift-mode.serializer')
    return Zone(
        S.deserialize(data.name),
        S.deserialize(data.outsideLine),
        S.deserialize(data.insideLine),
        S.deserialize(data.maxPoints),
        S.deserialize(data.collide)
    )
end

---@private
function Zone:recalculatePolygon()
    if not self.outsideLine or not self.insideLine then
        self.polygon = nil
        return
    end

    local points = {}
    for _, insidePoint in self:getInsideLine():iter() do
        points[#points + 1] = insidePoint
    end

    local rev_idx = 0
    for _, outsidePoint in self:getOutsideLine():iter() do
        local idx = self:getInsideLine():count() + self:getOutsideLine():count() - rev_idx
        points[idx] = outsidePoint
        rev_idx = rev_idx + 1
    end

    self.polygon = PointGroup(points)
end

function Zone:gatherColliders()
    if not self.collide then return {} end

    local colliders = {}

    for idx, segment in self:getOutsideLine():segment():iter() do
        local parallel = (segment.tail:value() - segment.head:value()):normalize()
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

function Zone:setDirty()
    self:realignZonePointOnTrack()
    self:recalculatePolygon()
    self:recalculateBoundingBox()
end

function Zone:setCollide(value)
    self.collide = value
end

function Zone:getCollide()
    return self.collide
end

function Zone:getOutsideLine()
    return self.outsideLine
end

function Zone:getInsideLine()
    return self.insideLine
end

function Zone:setOutsideLine(outside_line)
    self.outsideLine = outside_line
    self:setDirty()
end

function Zone:setInsideLine(inside_line)
    self.insideLine = inside_line
    self:setDirty()
end

---Joins outside and inside lines to form a closed polygon
---@param self Zone
---@return PointGroup?
function Zone:getPolygon()
    return self.polygon
end

---Check if the point is inside the zone
---@param self Zone
---@param point Point
---@param custom_origin Point? Custom origin point, to check corretly it must be outside the zone
---@return boolean
function Zone:isInZone(point, custom_origin)
    -- TODO: Cache bounding_box in class
    local bounding_box = self:getBoundingBox()
    if bounding_box ~= nil and
        point:flat().x < bounding_box.p1:flat().x or
        point:flat().y < bounding_box.p1:flat().y or
        point:flat().y > bounding_box.p2:flat().y or
        point:flat().y > bounding_box.p2:flat().y
    then
        return false
    end

    local origin = custom_origin or Point(vec3(0, 0, 0))

    --DEBUG local hits = {}
    local hit_no = 0

    for _, segment in self:getPolygon():segment(true):iter() do
        local hit = vec2.intersect(
            origin:flat(),
            point:flat(),
            segment.head:flat(),
            segment.tail:flat()
        )

        if hit then
            hit_no = hit_no + 1
            --DEBUG hits[hit_no] = hit
        end
    end

    return hit_no % 2 == 1
end

---Check if a segment is inside the zone. Relatively expensive to compute.
---
---Naively assumes there's only one intersection. If both segment end-points are either in
---or out it assumes the whole segment is in or out.
---@param self Zone
---@param segment Segment
---@param custom_origin Point? Custom origin point, to check corretly it must be outside the zone
---@return number fraction Fraction of the segment inside the zone: `1.0` fully inside, `0.0` fully outside
function Zone:isSegmentInZone(segment, custom_origin)
    local is_head_in_zone = self:isInZone(segment.head, custom_origin)
    local is_tail_in_zone = self:isInZone(segment.tail, custom_origin)

    if not is_head_in_zone and not is_tail_in_zone then return 0.0 end
    if is_head_in_zone and is_tail_in_zone then return 1.0 end

    -- Find which zone part is crossing the segment
    for _, zone_segment in self:getPolygon():segment(true):iter() do
        local hit = vec2.intersect(
            segment.head:flat(),
            segment.tail:flat(),
            zone_segment.head:flat(),
            zone_segment.tail:flat()
        )

        if hit then
            if is_head_in_zone then
                return segment.head:flat():distance(hit) / segment:lengthFlat()
            else -- is_tail_in_zone then
                return segment.tail:flat():distance(hit) / segment:lengthFlat()
            end
        end
    end

    Assert.Error([[
        Calculated that either head or tail are in zone,
        while the segment does not intersect with any of the zone's polygon sides]]
    ---@diagnostic disable-next-line: missing-return
    )
end

local function rotateVec2(v, theta)
    local new_x = v.x * math.cos(theta) - v.y * math.sin(theta)
    local new_y = v.x * math.sin(theta) + v.y * math.cos(theta)

    return vec2(new_x, new_y)
end

---@param self Zone
---@param point Point
---@return table
function Zone:shortestCrossline(point)
    local direction_candidates = {}
    local ray_count = 45

    for i = 1, ray_count do
        direction_candidates[i] = rotateVec2(vec2(0, 100), math.pi / ray_count * i)
    end

    local shortest = {
        segment = nil, ---@type Segment
        out_no = 0,
        in_no = 0
    }

    for i = 1, ray_count do
        local dir = direction_candidates[i]

        local out_hit = { hit = nil, distance = 999, segment_no = 0 }
        local in_hit = { hit = nil, distance = 999, segment_no = 0 }

        for idx, segment in self.outsideLine:segment():iter() do
            local segment_center = (segment.head:flat() + segment.tail:flat()) / 2
            local segment_distance = point:flat():distance(segment_center)
            if segment_distance < out_hit.distance then
                local segment_hit = vec2.intersect(
                    point:flat() + dir,
                    point:flat() - dir,
                    segment.head:flat(),
                    segment.tail:flat()
                )
                if segment_hit ~= nil then
                    out_hit.hit = segment_hit
                    out_hit.distance = segment_distance
                    out_hit.segment_no = idx
                end
            end
        end

        for idx, segment in self.insideLine:segment():iter() do
            local segment_center = (segment.head:flat() + segment.tail:flat()) / 2
            local segment_distance = point:flat():distance(segment_center)
            if segment_distance < in_hit.distance then
                local segment_hit = vec2.intersect(
                    point:flat() + dir,
                    point:flat() - dir,
                    segment.head:flat(),
                    segment.tail:flat()
                )
                if segment_hit ~= nil then
                    in_hit.hit = segment_hit
                    in_hit.distance = segment_distance
                    in_hit.segment_no = idx
                end
            end
        end

        if out_hit.hit ~= nil and in_hit.hit ~= nil then
            if shortest.segment == nil then
                shortest = {
                    segment = Segment(
                        Point(vec3(out_hit.hit.x, 0, out_hit.hit.y)),
                        Point(vec3(in_hit.hit.x, 0, in_hit.hit.y))),
                    out_no = out_hit.segment_no,
                    in_no = in_hit.segment_no
                }
            else
                local shortest_lenght = shortest.segment.head:flat():distance(shortest.segment.tail:flat())
                local new_lenght = out_hit.hit:distance(in_hit.hit)

                if shortest_lenght > new_lenght then
                    shortest = {
                        segment = Segment(
                            Point(vec3(out_hit.hit.x, 0, out_hit.hit.y)),
                            Point(vec3(in_hit.hit.x, 0, in_hit.hit.y))),
                        out_no = out_hit.segment_no,
                        in_no = in_hit.segment_no
                    }
                end
            end
        end
    end

    return shortest
end

---Return a segment that is the entry gate of the zone, ie. segment between first
---inside line point and first outside line point.
---@param self Zone
---@return Segment?
function Zone:getStartGate()
    if self:getInsideLine():count() == 0 or self:getOutsideLine():count() == 0 then
        return nil
    end

    return Segment(self:getInsideLine():get(1), self:getOutsideLine():get(1))
end

function Zone:getCenter()
    local segment = Segment()
    if self:getInsideLine():count() > 0 then
        segment.head = self:getInsideLine():get(math.floor(self:getInsideLine():count() / 2 + 0.5))
    end

    if self:getOutsideLine():count() > 0 then
        segment.tail = self:getOutsideLine():get(math.floor(self:getOutsideLine():count() / 2 + 0.5))
    end

    if segment.head and segment.tail then
        return segment:getCenter()
    elseif segment.head then
        return segment.head
    elseif segment.tail then
        return segment.tail
    else
        return nil
    end
end

---Moves all zone points such that the passed point
---becomes the zones centroid (visual center).
---@param point Point
function Zone:setZonePosition(point)
    local origin = self:getCenter()
    local offset = point - origin:value()

    for _, inside_point in self:getInsideLine():iter() do
        inside_point:set(inside_point:value() + offset)
    end
    for _, outside_point in self:getOutsideLine():iter() do
        outside_point:set(outside_point:value() + offset)
    end

    self:setDirty()
end

function Zone:realignZonePointOnTrack()
    if self.insideLine then
        for _, inside_point in self:getInsideLine():iter() do
            RaycastUtils.alignPointToTrack(inside_point)
        end
    end
    if self.outsideLine then
        for _, outside_point in self:getOutsideLine():iter() do
            RaycastUtils.alignPointToTrack(outside_point)
        end
    end
end

function Zone:getBoundingBox()
    if self:isEmpty() then
        return nil
    end
    if self.bounding_box == nil then
        self:recalculateBoundingBox()
    end

    return self.bounding_box
end

function Zone:isEmpty()
    if self.insideLine == nil and self.outsideLine == nil then return true end

    if self.insideLine and self.insideLine:count() == 0 and
        self.outsideLine and self.outsideLine:count() == 0 then
        return true
    end

    return false
end

function Zone:recalculateBoundingBox()
    -- TODO: Add padding for inZone detection
    local pMin = vec3(9999, 9999, 9999)
    local pMax = vec3(-9999, -9999, -9999)

    if self:getInsideLine() ~= nil then
        for _, point in self:getInsideLine():iter() do
            pMin:min(point:value())
            pMax:max(point:value())
        end
    end

    if self:getOutsideLine() ~= nil then
        for _, point in self:getOutsideLine():iter() do
            pMin:min(point:value())
            pMax:max(point:value())
        end
    end

    self.bounding_box = { p1 = Point(pMin), p2 = Point(pMax) }
end

function Zone:drawFlat(coord_transformer, scale)
    local color = Resources.Colors

    for _, seg in self:getOutsideLine():segment(false):iter() do
        local head_mapped = coord_transformer(seg.head)
        local tail_mapped = coord_transformer(seg.tail)
        ui.drawLine(head_mapped, tail_mapped, rgbm.colors.white, 1 * scale)
    end

    for _, seg in self:getInsideLine():segment(false):iter() do
        local head_mapped = coord_transformer(seg.head)
        local tail_mapped = coord_transformer(seg.tail)
        ui.drawLine(head_mapped, tail_mapped, rgbm.colors.white, 0.5 * scale)
    end
end

local Assert = require('drift-mode.assert')
local function test()
    -- Zone.isSegmentInZone
    --   For debugging these it'd be best to draw a coordinate plane (x, z) and check
    local inside = PointGroup({
        Point(vec3(0, 0, 0)),
        Point(vec3(1, 0, 0)) })
    local outside = PointGroup({
        Point(vec3(0, 0, 1)),
        Point(vec3(1, 0, 1)) })

    local zone = Zone("test", outside, inside, 0)
    local custom_origin = Point(vec3(23.45, 0, 51.23))

    local segment = Segment(
        Point(vec3(2, 0, 0)),
        Point(vec3(2, 0, 2)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 0.0, "Zone.isZoneInSegment() test failed")

    segment = Segment(
        Point(vec3(0.1, 0, 0.1)),
        Point(vec3(0.5, 0, 0.8)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 1.0, "Zone.isZoneInSegment() test failed")

    segment = Segment(
        Point(vec3(0.5, 0, 0.5)),
        Point(vec3(0.5, 0, 2.5)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 0.25, "Zone.isZoneInSegment() test failed")

    segment = Segment(
        Point(vec3(0.5, 0, 0.5)),
        Point(vec3(0.5, 0, 4.5)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 0.125, "Zone.isZoneInSegment() test failed")

    segment = Segment(
        Point(vec3(0.5, 0, 4.5)),
        Point(vec3(0.5, 0, 0.5)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 0.125, "Zone.isZoneInSegment() test failed")

    segment = Segment(
        Point(vec3(0.5, 0, 2.5)),
        Point(vec3(0.5, 0, 0.5)))
    Assert.Equal(zone:isSegmentInZone(segment, custom_origin), 0.25, "Zone.isZoneInSegment() test failed")
end
test()

return Zone
