local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ObjectEditorPoi : ClassBase
---@field point Point
---@field poi_type ObjectEditorPoi.Type
local ObjectEditorPoi = class("ObjectEditorPoi")
ObjectEditorPoi.__model_path = "CourseEditorUtils.POIs.ObjectEditorPoi"

---@enum ObjectEditorPoi.Type
ObjectEditorPoi.Type = {
    Zone = "Zone",
    Clip = "Clip",
    Segment = "Segment",
    StartingPoint = "StartingPoint"
}

function ObjectEditorPoi:initialize(point, poi_type)
    self.point = point
    self.poi_type = poi_type
end

function ObjectEditorPoi:set(new_pos)
    Assert.Error("Abstract method called")
end

return ObjectEditorPoi
