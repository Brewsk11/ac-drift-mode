local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Zone Class representing a drift scoring zone
---@field name string Name of the zone
---@field private outsideLine PointGroup Outside zone line definition
---@field private insideLine PointGroup Inside zone line definition
---@field private polygon PointGroup Polygon created from inside and outside lines
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run)
local Zone = {}
Zone.__index = Zone

local color_outside = rgbm(0, 3, 0, 0.4)
local color_inside = rgbm(0, 0, 3, 0.4)

function Zone.serialize(self)
    local data = {
        __class = "Zone",
        name = S.serialize(self.name),
        outsideLine = self.outsideLine:serialize(),
        insideLine = self.insideLine:serialize(),
        maxPoints = S.serialize(self.maxPoints)
    }
    return data
end

function Zone.deserialize(data)
    Assert.Equal(data.__class, "Zone", "Tried to deserialize wrong class")

    local obj = Zone.new(
        S.deserialize(data.name),
        PointGroup.deserialize(data.outsideLine),
        PointGroup.deserialize(data.insideLine),
        S.deserialize(data.maxPoints)
    )
    return obj
end

---@param name string
---@param outsideLine PointGroup
---@param insideLine PointGroup
---@param maxPoints integer
---@return Zone
function Zone.new(name, outsideLine, insideLine, maxPoints)
    local self = setmetatable({}, Zone)

    self.name = name
    self:setOutsideLine(outsideLine)
    self:setInsideLine(insideLine)
    self.maxPoints = maxPoints

    return self
end

---@private
function Zone.calculatePolygon(self)
    if not self.outsideLine or not self.insideLine then
        self.polygon = nil
        return
    end

    local points = {}
    for _, insidePoint in self.insideLine:iter() do
        points[#points+1] = insidePoint
    end

    local rev_idx = 0
    for _, outsidePoint in self.outsideLine:iter() do
        local idx = self.insideLine:count() + self.outsideLine:count() - rev_idx
        points[idx] = outsidePoint
        rev_idx = rev_idx + 1
    end

    self.polygon = PointGroup.new(points)
end

function Zone.getOutsideLine(self)
    return self.outsideLine
end

function Zone.getInsideLine(self)
    return self.insideLine
end

function Zone.setOutsideLine(self, outside_line)
    self.outsideLine = outside_line
    self:calculatePolygon()
end

function Zone.setInsideLine(self, inside_line)
    self.insideLine = inside_line
    self:calculatePolygon()
end

---Joins outside and inside lines to form a closed polygon
---@param self Zone
---@return PointGroup?
function Zone.getPolygon(self)
    return self.polygon
end

---Check if the point is inside the zone
---@param self Zone
---@param point Point
---@param custom_origin Point? Custom origin point, to check corretly it must be outside the zone
---@return boolean
function Zone.isInZone(self, point, custom_origin)
    local origin = custom_origin or Point.new("origin", vec3(0, 0, 0))

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

    if hit_no % 2 == 1 then return true else return false end
end


local function rotateVec2(v, theta)
    local new_x = v.x * math.cos(theta) - v.y * math.sin(theta)
    local new_y = v.x * math.sin(theta) + v.y * math.cos(theta)

    return vec2(new_x, new_y)
end

---@param self Zone
---@param point Point
---@return Segment
function Zone.shortestCrossline(self, point)
    Assert.NotEqual(self.polygon, nil, "Cannot calculate crossline with no precalculated polygon")

    local direction_candidates = {}
    local ray_count = 180

    for i = 1, ray_count do
        direction_candidates[i] = rotateVec2(vec2(0, 100), math.pi / ray_count * i)
    end

    local shortest = nil

    for i = 1, ray_count do
        local dir = direction_candidates[i]

        local out_hit = { hit = nil, distance = 999 }
        local in_hit = { hit = nil, distance = 999 }

        for _, segment in self.outsideLine:segment():iter() do
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
                out_hit = { hit = segment_hit, distance = segment_distance }
                end
            end
        end

        for _, segment in self.insideLine:segment():iter() do
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
                in_hit = { hit = segment_hit, distance = segment_distance }
                end
            end
        end

        if out_hit.hit ~= nil and in_hit.hit ~= nil then
            if shortest == nil then
                shortest = Segment.new(
                    Point.new("out_hit", vec3(out_hit.hit.x, 0, out_hit.hit.y)),
                    Point.new("in_hit", vec3(in_hit.hit.x, 0, in_hit.hit.y))
                )
            else
                local shortest_lenght = shortest.head:flat():distance(shortest.tail:flat())
                local new_lenght = out_hit.hit:distance(in_hit.hit)

                if shortest_lenght > new_lenght then
                    shortest = Segment.new(
                        Point.new("out_hit", vec3(out_hit.hit.x, 0, out_hit.hit.y)),
                        Point.new("in_hit", vec3(in_hit.hit.x, 0, in_hit.hit.y))
                    )
                end
            end
        end
    end

    return shortest
end

function Zone.drawWall(self, color)
    self.outsideLine:segment():drawWall(1, color)
    self.insideLine:segment():drawWall(0.1, color)
end

function Zone.drawSetup(self)
    self.outsideLine:draw(0.2, color_outside, true)
    self.outsideLine:segment():draw(color_outside)

    self.insideLine:draw(0.2, color_inside, true)
    self.insideLine:segment():draw(color_inside)
end

local Assert = require('drift-mode/assert')
local function test()
end
test()

return Zone
