local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local ObjectEditorPoi = require('drift-mode/models/CourseEditorUtils/POIs/ObjectEditorPoi')

---@class PoiSegment : ObjectEditorPoi
---@field segment Segment
---@field segment_type PoiSegment.Type
---@field segment_point_type PoiSegment.Part
local PoiSegment = class("PoiSegment", ObjectEditorPoi)
PoiSegment.__model_path = "CourseEditorUtils.POIs.PoiSegment"

---@enum PoiSegment.Type
PoiSegment.Type = {
    StartLine = "StartLine",
    FinishLine = "FinishLine",
    RespawnLine = "RespawnLine"
}

---@enum PoiSegment.Part
PoiSegment.Part = {
    Head = "Head",
    Tail = "Tail"
}

function PoiSegment:initialize(point, segment, segment_type, segment_point_type)
    ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.Segment)
    self.segment = segment
    self.segment_type = segment_type
    self.segment_point_type = segment_point_type
end

function PoiSegment:set(new_pos)
    if self.segment_point_type == PoiSegment.Part.Head then
        self.segment.head:set(new_pos)
    elseif self.segment_point_type == PoiSegment.Part.Tail then
        self.segment.tail:set(new_pos)
    end
end

return PoiSegment
