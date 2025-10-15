local ObjectEditorPoi = require('drift-mode.models.Editor.POIs.Base')

---@class PoiZone : ObjectEditorPoi
---@field zone Zone
---@field point_type PoiZone.Type
---@field point_index integer
local PoiZone = class("PoiZone", ObjectEditorPoi)
PoiZone.__model_path = "Editor.POIs.Zone"

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

---@param zone Zone
---@return PoiZone[]
function PoiZone.gatherPois(zone)
    local pois = {}
    for idx, inside_point in zone:getInsideLine():iter() do
        pois[#pois + 1] = PoiZone(
            inside_point,
            zone,
            PoiZone.Type.FromInsideLine,
            idx
        )
    end
    for idx, outside_point in zone:getOutsideLine():iter() do
        pois[#pois + 1] = PoiZone(
            outside_point,
            zone,
            PoiZone.Type.FromOutsideLine,
            idx
        )
    end
    local zone_center = zone:getCenter()
    if zone_center then
        pois[#pois + 1] = PoiZone(
            zone_center,
            zone,
            PoiZone.Type.Center,
            nil
        )
    end
    return pois
end

function PoiZone:set(new_pos)
    if self.point_type == PoiZone.Type.Center then
        self.zone:setZonePosition(new_pos)
    else
        self.point:set(new_pos)
    end
end

return PoiZone
