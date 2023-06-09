local Assert = require('drift-mode/assert')
local Segment = require('drift-mode/models/Segment')

---@class SegmentGroup Ordered group of segments
---@field segments Segment[]
local SegmentGroup = {}
SegmentGroup.__index = SegmentGroup

function SegmentGroup.serialize(self)
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

    return SegmentGroup.new(segments)
end

---@param segments Segment[]?
---@return SegmentGroup
function SegmentGroup.new(segments)
    local self = setmetatable({}, SegmentGroup)

    local _segments = segments or {}
    self.segments = _segments
    return self
end

---Get count of the segments in group
---@param self SegmentGroup
---@return integer
function SegmentGroup.count(self)
    return #self.segments
end

---Append a segment at the end of the group
---@param self SegmentGroup
---@param segment Segment
function SegmentGroup.append(self, segment)
    self.segments[#self.segments+1] = segment
end

---Pop the last segment from the group
---@param self SegmentGroup
---@return Segment
function SegmentGroup.pop(self)
    local segment = self.segments[self:count()]
    self.segments[self:count()] = nil
    return segment
end

---Is every segment's tail at the same point as next's segment head
---@param self SegmentGroup
---@return boolean
function SegmentGroup.continuous(self)
    Assert.MoreThan(self:count(), 0, "Cannot calculate continous on empty set")
    for idx = 1, self:count() - 1 do
        if self.segments[idx].tail:value() ~= self.segments[idx+1].head:value() then
            return false
        end
    end
    return true
end

---Is the group continous and is last segment connected to the first
---@param self SegmentGroup
---@return boolean
function SegmentGroup.closed(self)
    Assert.MoreThan(self:count(), 0, "Cannot calculate closed on empty set")
    return
        self:continuous() and
        self.segments[self:count()].tail:value() == self.segments[1].head:value()
end

---Return an iterator like `ipairs()` iterating over segments
---@param self SegmentGroup
function SegmentGroup.iter(self)
    return ipairs(self.segments)
end

function SegmentGroup.draw(self, color)
    for _, segment in self:iter() do
        segment:draw(color)
    end
end

function SegmentGroup.drawWall(self, height, color)
    for _, segment in self:iter() do
        segment:drawWall(color, height)
    end
end

local function test()
    local points = {
        Point.new(vec3(1, 1, 1)),
        Point.new(vec3(2, 2, 2)),
        Point.new(vec3(3, 3, 3)),
        Point.new(vec3(4, 4, 4))
    }

    local segments = {
        Segment.new(points[1], points[2]),
        Segment.new(points[2], points[3])
    }

    -- SegmentGroup.new()
    local grp = SegmentGroup.new()
    Assert.NotEqual(grp.segments, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(#grp.segments, 0, "Segment table length not zero")

    -- SegmentGroup.new(segments)
    -- SegmentGroup:length()
    local grp = SegmentGroup.new(segments)
    Assert.NotEqual(grp.segments, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(grp:count(), 2, "Incorrect segment count when initializing SegmentGroup from table")

    -- SegmentGroup:append()
    grp:append(Segment.new(points[3], points[4]))
    Assert.Equal(grp:count(), 3, "Incorrect segment count after appending a segment")

    -- SegmentGroup:continous()
    Assert.Equal(grp:continuous(), true, "The segment group does not seem to be continous, whereas it should be")
    local seg_test_a = Segment.new(points[3], points[1])
    grp:append(seg_test_a)
    Assert.Equal(grp:continuous(), false, "The segment group does seem to be continous, whereas it should not be")

    -- SegmentGroup:pop()
    local seg_test_b = grp:pop()
    local a_head, a_tail = seg_test_a:get()
    local b_head, b_tail = seg_test_b:get()
    Assert.Equal(a_head, b_head, "The popped segment is incorrect")
    Assert.Equal(a_tail, b_tail, "The popped segment is incorrect")

    -- Segment:closed()
    grp:append(Segment.new(points[4], points[1]))
    Assert.Equal(grp:closed(), true, "The segment group does not seem to be closed, whereas it should be")
    grp:append(Segment.new(points[1], points[2]))
    Assert.Equal(grp:closed(), false, "The segment group does seem to be closed, whereas it should not be")
end
test()

return SegmentGroup
