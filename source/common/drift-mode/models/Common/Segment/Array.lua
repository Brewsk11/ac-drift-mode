local Array = require("drift-mode.models.Common.Array")
local Assert = require('drift-mode.assert')

---@class SegmentArray : Array<Segment>
local SegmentArray = class("SegmentArray", Array)
SegmentArray.__model_path = "Common.Segment.Array"

function SegmentArray:initialize(items)
    Array.initialize(self, items)
end

-- Needed for 2.7.1 migration, remove afterwards.
function SegmentArray.__deserialize(data)
    local S = require('drift-mode.serializer')
    local items = data.segments or data._items
    return SegmentArray(S.deserialize(items))
end

---Is every segment's tail at the same point as next's segment head
---@return boolean
function SegmentArray:continuous()
    Assert.MoreThan(self:count(), 0, "Cannot calculate continous on empty set")
    for idx = 1, self:count() - 1 do
        if self:get(idx).tail:value() ~= self:get(idx + 1).head:value() then
            return false
        end
    end
    return true
end

---Is the group continous and is last segment connected to the first
---@param self SegmentArray
---@return boolean
function SegmentArray:closed()
    Assert.MoreThan(self:count(), 0, "Cannot calculate closed on empty set")
    return
        self:continuous() and
        self:get(self:count()).tail:value() == self:get(1).head:value()
end

local function test()
    local Point = require("drift-mode.models.Common.Point.Point")
    local Segment = require('drift-mode.models.Common.Segment.Segment')

    local points = {
        Point(vec3(1, 1, 1)),
        Point(vec3(2, 2, 2)),
        Point(vec3(3, 3, 3)),
        Point(vec3(4, 4, 4))
    }

    local segments = {
        Segment(points[1], points[2]),
        Segment(points[2], points[3])
    }

    -- SegmentArray(segments)
    -- SegmentArray:length()
    local grp = SegmentArray(segments)
    Assert.NotEqual(grp:getItems(), nil, "Empty constructor did not initialize segment table")
    Assert.Equal(grp:count(), 2, "Incorrect segment count when initializing SegmentArray from table")

    -- SegmentArray:append()
    grp:append(Segment(points[3], points[4]))
    Assert.Equal(grp:count(), 3, "Incorrect segment count after appending a segment")

    -- SegmentArray:continous()
    Assert.Equal(grp:continuous(), true, "The segment group does not seem to be continous, whereas it should be")
    local seg_test_a = Segment(points[3], points[1])
    grp:append(seg_test_a)
    Assert.Equal(grp:continuous(), false, "The segment group does seem to be continous, whereas it should not be")

    -- SegmentArray:pop()
    local seg_test_b = grp:pop()
    local a_head, a_tail = seg_test_a:get()
    local b_head, b_tail = seg_test_b:get()
    Assert.Equal(a_head, b_head, "The popped segment is incorrect")
    Assert.Equal(a_tail, b_tail, "The popped segment is incorrect")

    -- Segment:closed()
    grp:append(Segment(points[4], points[1]))
    Assert.Equal(grp:closed(), true, "The segment group does not seem to be closed, whereas it should be")
    grp:append(Segment(points[1], points[2]))
    Assert.Equal(grp:closed(), false, "The segment group does seem to be closed, whereas it should not be")
end
test()

return class.emmy(SegmentArray, SegmentArray.initialize)
