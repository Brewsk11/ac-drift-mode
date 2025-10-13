local Array = require("drift-mode.models.Common.Array")
local Assert = require('drift-mode.assert')

local Segment = require('drift-mode.models.Common.Segment.Segment')
local SegmentArray = require("drift-mode.models.Common.Segment.Array")

---@class PointArray : Array<Point>
local PointArray = class("PointArray", Array)
PointArray.__model_path = "Common.Point.Array"

function PointArray:initialize(items)
    Array.initialize(self, items)

    self._segmented_closed = nil
    self._segmented_opened = nil
end

function PointArray:setDirty()
    Array.setDirty(self)
    self._segment_closed = self:recalcSegment(true)
    self._segmented_opened = self:recalcSegment(false)
end

-- Needed for 2.7.1 migration, remove afterwards.
function PointArray.__deserialize(data)
    local S = require('drift-mode.serializer')
    local items = data.points or data._items
    return PointArray(S.deserialize(items))
end

function PointArray:segment(closed)
    if closed then
        if self._segment_closed == nil then
            self._segment_closed = self:recalcSegment(closed)
        end
        return self._segment_closed
    else
        if self._segmented_opened == nil then
            self._segmented_opened = self:recalcSegment(closed)
        end
        return self._segmented_opened
    end
end

---Segment the group. For group with 1 points returns empty SegmentArray.
---@param closed boolean? Whether to connect first with last point as last segment
---@return SegmentArray
function PointArray:recalcSegment(closed)
    local _closed = closed or false

    local segments = {}
    for idx = 1, self:count() do
        if idx < self:count() then
            segments[idx] = Segment(self:get(idx), self:get(idx + 1))
        elseif _closed then -- Connect last with first
            segments[idx] = Segment(self:get(idx), self:get(1))
        end
    end

    local res = SegmentArray(segments)
    return res
end

local function test()
    local Point = require('drift-mode.models.Common.Point.Point')

    local points = {}
    points[1] = Point(vec3(1, 1, 1))
    points[2] = Point(vec3(2, 2, 2))
    points[3] = Point(vec3(3, 3, 3))

    -- PointArray()
    local group = PointArray()
    Assert.NotEqual(group:getItems(), nil, "Group did not correctly initialize, points table is nil")

    -- PointArray(points)
    group = PointArray(points)
    Assert.NotEqual(group:getItems(), nil, "Group did not correctly initialize, points table is nil")

    -- PointArray:count()
    Assert.Equal(group:count(), 3, "Group did not correctly initialize, incorrect number of points returned")

    -- PointArray:append(point)
    group:append(Point(vec3(4, 4, 4)))
    Assert.Equal(group:count(), 4, "Point did not append correctly to the group")

    -- PointArray:last()
    -- PointArray:first()
    Assert.Equal(Point(vec3(4, 4, 4)):value(), group:last():value())
    Assert.Equal(Point(vec3(1, 1, 1)):value(), group:first():value())

    -- PointArray:remove(idx)
    group:remove(1)
    Assert.Equal(group:get(1):value(), vec3(2, 2, 2))
end
test()

return class.emmy(PointArray, PointArray.initialize)
