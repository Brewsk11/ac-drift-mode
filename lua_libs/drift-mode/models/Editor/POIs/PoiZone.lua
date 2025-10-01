local ObjectEditorPoi = require('drift-mode.models.Editor.POIs.ObjectEditorPoi')

---@class PoiZone : ObjectEditorPoi
---@field zone Zone
---@field point_type PoiZone.Type
---@field point_index integer
local PoiZone = class("PoiZone", ObjectEditorPoi)
PoiZone.__model_path = "Editor.POIs.PoiZone"

---@enum PoiZone.Type
PoiZone.Type = {
    FromInsideLine = "FromInsideLine",
    FromOutsideLine = "FromOutsideLine",
    Center = "Center"
}

function PoiZone:initialize(point, zone, zone_obj_type, point_index)
    ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.Zone)
    self.zone = zone
    self.point_type = zone_obj_type
    self.point_index = point_index
end

function PoiZone:set(new_pos)
    if self.point_type == PoiZone.Type.Center then
        self.zone:setZonePosition(new_pos)
    else
        self.point:set(new_pos)
    end
end

return PoiZone
