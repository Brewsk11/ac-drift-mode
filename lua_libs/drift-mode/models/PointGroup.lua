local Assert = require('drift-mode/assert')

local Point = require('drift-mode/models/Point')
local Segment = require('drift-mode/models/Segment')

---@class PointGroup : ClassBase Ordered group of points in world space
---@field points Point[]
local PointGroup = class("PointGroup")

---@param points Point[]?
function PointGroup:initialize(points)
    local _points = points or {}
    self.points = _points
end

function PointGroup:serialize()
    local data = {
        __class = "PointGroup",
        points = {}
    }

    for idx, point in ipairs(self.points) do
        data.points[idx] = point:__serialize()
    end

    return data
end

function PointGroup.deserialize(data)
    Assert.Equal(data.__class, "PointGroup", "Tried to deserialize wrong class")

    local obj = PointGroup()

    local points = {}
    for idx, point in ipairs(data.points) do
        points[idx] = Point.__deserialize(point)
    end

    obj.points = points
    return obj
end

---Append a point to the end of the gropu
---@param self PointGroup
---@param point Point
function PointGroup:append(point)
    self.points[#self.points+1] = point
end

---Return number of points in the group
---@param self PointGroup
---@return integer
function PointGroup:count()
    return #self.points
end

---Get a point from the group
---@param self PointGroup
---@param idx integer Index of the point in the group
---@return Point
function PointGroup:get(idx)
    assert(self:count() >= idx, "Point index (" .. tostring(idx) .. ") out of range (" .. self:count() .. ")")
    return self.points[idx]
end

---Get first point from the group
---@param self PointGroup
---@return Point
function PointGroup:first()
    assert(self:count() > 0, "Group is empty")
    return self.points[1]
end

---Get Last point from the group
function PointGroup:last()
    assert(self:count() > 0, "Group is empty")
    return self.points[#self.points]
end

---Segment the group. For group with 1 points returns empty SegmentGroup.
---@param self PointGroup
---@param closed boolean? Whether to connect first with last point as last segment
---@return SegmentGroup
function PointGroup:segment(closed)
    local _closed = closed or false

    local segments = {}
    for idx = 1, self:count() do
        if idx < self:count() then
            segments[idx] = Segment(self.points[idx], self.points[idx + 1])
        elseif _closed then -- Connect last with first
            segments[idx] = Segment(self.points[idx], self.points[1])
        end
    end
    return SegmentGroup(segments)
end

---Return an iterator like `ipairs()` iterating over points
---@param self PointGroup
function PointGroup:iter()
    return ipairs(self.points)
end

---Return an iterator like `ipairs()` iterating over point vec3 values
---@param self PointGroup
function PointGroup:iterVal()
    local points = {}
    for k, v in ipairs(self.points) do
        points[k] = v:value()
    end
    return ipairs(points)
end

---Return an iterator like `ipairs()` iterating over flatten vec2 point values
---@param self PointGroup
function PointGroup:iterFlat()
    local flats = {}
    for k, v in ipairs(self.points) do
        flats[k] = v:flat()
    end
    return ipairs(flats)
end

---Return an iterator like `ipairs()` iterating over projected vec3 point values
---@param self PointGroup
function PointGroup:iterProjected()
    local projects = {}
    for k, v in ipairs(self.points) do
        projects[k] = v:projected()
    end
    return ipairs(projects)
end

---Pop the last segment from the group
---@param self PointGroup
---@return Point
function PointGroup:pop()
    local point = self.points[self:count()]
    self.points[self:count()] = nil
    return point
end

---Remove point at index
---@param self PointGroup
---@param idx integer
---@return Point
function PointGroup:remove(idx)
    Assert.LessOrEqual(idx, self:count(), "Out-of-bounds error")
    local point = self.points[idx]
    table.remove(self.points, idx)
    return point
end

---Remove allow points with equal value
---@param self PointGroup
---@param point Point
---@return boolean -- True if deleted any point
function PointGroup:delete(point)
    return table.removeItem(self.points, point)
end

function PointGroup:draw(size, color, number)
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
    points[1] = Point(vec3(1, 1, 1))
    points[2] = Point(vec3(2, 2, 2))
    points[3] = Point(vec3(3, 3, 3))

    -- PointGroup()
    local group = PointGroup()
    Assert.NotEqual(group.points, nil, "Group did not correctly initialize, points table is nil")

    -- PointGroup(points)
    group = PointGroup(points)
    Assert.NotEqual(group.points, nil, "Group did not correctly initialize, points table is nil")

    -- PointGroup:count()
    Assert.Equal(group:count(), 3, "Group did not correctly initialize, incorrect number of points returned")

    -- PointGroup:append(point)
    group:append(Point(vec3(4, 4, 4)))
    Assert.Equal(group:count(), 4, "Point did not append correctly to the group")

    -- PointGroup:last()
    -- PointGroup:first()
    Assert.Equal(Point(vec3(4, 4, 4)):value(), group:last():value())
    Assert.Equal(Point(vec3(1, 1, 1)):value(), group:first():value())

    -- PointGroup:iterVal()
    -- PointGroup:iterFlat()
    -- PointGroup:iterProjected()
    for k, v in group:iterVal()       do Assert.Equal(v, vec3(k, k, k), "Incorrect point value returned") end
    for k, v in group:iterFlat()      do Assert.Equal(v, vec2(k, k),    "Incorrect flat point value returned") end
    for k, v in group:iterProjected() do Assert.Equal(v, vec3(k, 0, k), "Incorrect projected point value returned") end

    -- PointGroup:remove(idx)
    group:remove(1)
    Assert.Equal(group:get(1):value(), vec3(2, 2, 2))
end
test()

return PointGroup
