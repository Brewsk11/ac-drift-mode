---@class SegmentGroup Ordered group of segments
---@field segments Segment[]
local SegmentGroup = {}
SegmentGroup.__index = SegmentGroup

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

local Assert = require('drift-mode/assert')
local function test()
    local points = {
        Point.new("a", vec3(1, 1, 1)),
        Point.new("b", vec3(2, 2, 2)),
        Point.new("c", vec3(3, 3, 3)),
        Point.new("d", vec3(4, 4, 4))
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
end
test()

return SegmentGroup
