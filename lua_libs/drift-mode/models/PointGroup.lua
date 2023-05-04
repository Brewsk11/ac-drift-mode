local Assert = require('drift-mode/assert')

local Point = require('drift-mode/models/Point')
local Segment = require('drift-mode/models/Segment')

---@class PointGroup Ordered group of points in world space
---@field points Point[]
local PointGroup = {}
PointGroup.__index = PointGroup

function PointGroup.serialize(self)
    local data = {
        __class = "PointGroup",
        points = {}
    }

    for idx, point in ipairs(self.points) do
        data.points[idx] = point:serialize()
    end

    return data
end

function PointGroup.deserialize(data)
    Assert.Equal(data.__class, "PointGroup", "Tried to deserialize wrong class")

    local obj = PointGroup.new()

    local points = {}
    for idx, point in ipairs(data.points) do
        points[idx] = Point.deserialize(point)
    end

    obj.points = points
    return obj
end

---@param points Point[]?
---@return PointGroup
function PointGroup.new(points)
    local self = setmetatable({}, PointGroup)

    local _points = points or {}
    self.points = _points
    return self
end

---Append a point to the end of the gropu
---@param self PointGroup
---@param point Point
function PointGroup.append(self, point)
    self.points[#self.points+1] = point
end

---Return number of points in the group
---@param self PointGroup
---@return integer
function PointGroup.count(self)
    return #self.points
end

---Get a point from the group
---@param self PointGroup
---@param idx integer Index of the point in the group
---@return Point
function PointGroup.get(self, idx)
    assert(PointGroup:count() < idx, "Point index (" .. tostring(idx) .. ") out of range (" .. PointGroup:count() ")")
    return self.points[idx]
end

---Get first point from the group
---@param self PointGroup
---@return Point
function PointGroup.first(self)
    assert(PointGroup:count() > 0, "Group is empty")
    return self.points[1]
end

---Get Last point from the group
function PointGroup.last(self)
    assert(PointGroup:count() > 0, "Group is empty")
    return self.points[#self.points]
end

---Segment the group. For group with 1 points returns empty SegmentGroup.
---@param self PointGroup
---@param closed boolean? Whether to connect first with last point as last segment
---@return SegmentGroup
function PointGroup.segment(self, closed)
    local _closed = closed or false

    local segments = {}
    for idx = 1, self:count() do
        if idx < self:count() then
            segments[idx] = Segment.new(self.points[idx], self.points[idx + 1])
        elseif _closed then -- Connect last with first
            segments[idx] = Segment.new(self.points[idx], self.points[1])
        end
    end
    return SegmentGroup.new(segments)
end

---Return an iterator like `ipairs()` iterating over points
---@param self PointGroup
function PointGroup.iter(self)
    return ipairs(self.points)
end

---Return an iterator like `ipairs()` iterating over point vec3 values
---@param self PointGroup
function PointGroup.iterVal(self)
    local points = {}
    for k, v in ipairs(self.points) do
        points[k] = v:value()
    end
    return ipairs(points)
end

---Return an iterator like `ipairs()` iterating over flatten vec2 point values
---@param self PointGroup
function PointGroup.iterFlat(self)
    local flats = {}
    for k, v in ipairs(self.points) do
        flats[k] = v:flat()
    end
    return ipairs(flats)
end

---Return an iterator like `ipairs()` iterating over projected vec3 point values
---@param self PointGroup
function PointGroup.iterProjected(self)
    local projects = {}
    for k, v in ipairs(self.points) do
        projects[k] = v:projected()
    end
    return ipairs(projects)
end

---Pop the last segment from the group
---@param self PointGroup
---@return Point
function PointGroup.pop(self)
    local point = self.points[self:count()]
    self.points[self:count()] = nil
    return point
end


function PointGroup.draw(self, size, color, number)
    local _number = number or false
    for idx, point in ipairs(self.points) do
        point:draw(size, color)
        if _number then
            render.debugText(point:value(), tostring(idx))
        end
    end
end

local function test()
    local points = {}
    points[1] = Point.new(vec3(1, 1, 1))
    points[2] = Point.new(vec3(2, 2, 2))
    points[3] = Point.new(vec3(3, 3, 3))

    -- PointGroup.new()
    local group = PointGroup.new()
    Assert.NotEqual(group.points, nil, "Group did not correctly initialize, points table is nil")

    -- PointGroup.new(points)
    group = PointGroup.new(points)
    Assert.NotEqual(group.points, nil, "Group did not correctly initialize, points table is nil")

    -- PointGroup:count()
    Assert.Equal(group:count(), 3, "Group did not correctly initialize, incorrect number of points returned")

    -- PointGroup:append(point)
    group:append(Point.new(vec3(4, 4, 4)))
    Assert.Equal(group:count(), 4, "Point did not append correctly to the group")

    -- PointGroup:iterVal()
    -- PointGroup:iterFlat()
    -- PointGroup:iterProjected()
    for k, v in group:iterVal()       do Assert.Equal(v, vec3(k, k, k), "Incorrect point value returned") end
    for k, v in group:iterFlat()      do Assert.Equal(v, vec2(k, k),    "Incorrect flat point value returned") end
    for k, v in group:iterProjected() do Assert.Equal(v, vec3(k, 0, k), "Incorrect projected point value returned") end
end
test()

return PointGroup
