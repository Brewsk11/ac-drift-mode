local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local ObjectEditorPoi = require('drift-mode/models/CourseEditorUtils/POIs/ObjectEditorPoi')

---@class PoiStartingPoint : ObjectEditorPoi
---@field starting_point StartingPoint
local PoiStartingPoint = class("PoiStartingPoint", ObjectEditorPoi)
PoiStartingPoint.__model_path = "CourseEditorUtils.POIs.PoiStartingPoint"

function PoiStartingPoint:initialize(point, starting_point)
  ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.StartingPoint)
  self.starting_point = starting_point
end

function PoiStartingPoint:set(new_pos)
  self.starting_point.origin:set(new_pos)
end

return PoiStartingPoint
