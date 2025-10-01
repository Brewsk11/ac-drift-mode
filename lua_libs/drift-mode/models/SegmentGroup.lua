local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode/assert')
local Segment = require('drift-mode/models/Segment')

local Point = require("drift-mode.models.Common.Point")


---@class SegmentGroup : ClassBase Ordered group of segments
---@field segments Segment[]
local SegmentGroup = class("SegmentGroup", ModelBase)
SegmentGroup.__model_path = "SegmentGroup"

---@param segments Segment[]?
function SegmentGroup:initialize(segments)
    self.segments = segments or {}
end

function SegmentGroup:serialize()
    local data = {
        __class = "SegmentGroup",
        segments = {}
    }

    for idx, segment in self:iter() do
        data.segments[idx] = segment:serialize()
    end

    return data
end

function SegmentGroup.deserialize(data)
    Assert.Equal(data.__class, "SegmentGroup", "Tried to deserialize wrong class")

    local segments = {}

    for idx, segment in data.segments do
        segments[idx] = Segment.deserialize(segment)
    end

    return SegmentGroup(segments)
end

---Get count of the segments in group
---@param self SegmentGroup
---@return integer
function SegmentGroup:count()
    return #self.segments
end

---Append a segment at the end of the group
---@param self SegmentGroup
---@param segment Segment
function SegmentGroup:append(segment)
    self.segments[#self.segments + 1] = segment
end

---Pop the last segment from the group
---@param self SegmentGroup
---@return Segment
function SegmentGroup:pop()
    local segment = self.segments[self:count()]
    self.segments[self:count()] = nil
    return segment
end

---Is every segment's tail at the same point as next's segment head
---@param self SegmentGroup
---@return boolean
function SegmentGroup:continuous()
    Assert.MoreThan(self:count(), 0, "Cannot calculate continous on empty set")
    for idx = 1, self:count() - 1 do
        if self.segments[idx].tail:value() ~= self.segments[idx + 1].head:value() then
            return false
        end
    end
    return true
end

---Is the group continous and is last segment connected to the first
---@param self SegmentGroup
---@return boolean
function SegmentGroup:closed()
    Assert.MoreThan(self:count(), 0, "Cannot calculate closed on empty set")
    return
        self:continuous() and
        self.segments[self:count()].tail:value() == self.segments[1].head:value()
end

---Return an iterator like `ipairs()` iterating over segments
---@param self SegmentGroup
function SegmentGroup:iter()
    return ipairs(self.segments)
end

-- TODO: Dependency injection
-- Migrate *Group classes to something more OOP
function SegmentGroup:draw(color)
    for _, segment in self:iter() do
        segment:draw()
    end
end

function SegmentGroup:drawWall(height, color)
    for _, segment in self:iter() do
        --segment:drawWall(color, height)
    end
end

local function test()
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

    -- SegmentGroup()
    local grp = SegmentGroup()
    Assert.NotEqual(grp.segments, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(#grp.segments, 0, "Segment table length not zero")

    -- SegmentGroup(segments)
    -- SegmentGroup:length()
    local grp = SegmentGroup(segments)
    Assert.NotEqual(grp.segments, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(grp:count(), 2, "Incorrect segment count when initializing SegmentGroup from table")

    -- SegmentGroup:append()
    grp:append(Segment(points[3], points[4]))
    Assert.Equal(grp:count(), 3, "Incorrect segment count after appending a segment")

    -- SegmentGroup:continous()
    Assert.Equal(grp:continuous(), true, "The segment group does not seem to be continous, whereas it should be")
    local seg_test_a = Segment(points[3], points[1])
    grp:append(seg_test_a)
    Assert.Equal(grp:continuous(), false, "The segment group does seem to be continous, whereas it should not be")

    -- SegmentGroup:pop()
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

return SegmentGroup
