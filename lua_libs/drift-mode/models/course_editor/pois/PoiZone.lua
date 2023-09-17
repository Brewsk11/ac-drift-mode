local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class PoiZone : ObjectEditorPoi
---@field zone Zone
---@field point_type PoiZone.Type
---@field point_index integer
local PoiZone = class("PoiZone", ObjectEditorPoi)

---@enum PoiZone.Type
PoiZone.Type = {
    FromInsideLine = "FromInsideLine",
    FromOutsideLine = "FromOutsideLine"
}

function PoiZone:initialize(point, zone, zone_obj_type, point_index)
    ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.Zone)
    self.zone = zone
    self.point_type = zone_obj_type
    self.point_index = point_index
end

function PoiZone:set(new_pos)
    self.point:set(new_pos)
end

return PoiZone
