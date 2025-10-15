local Poi = require('drift-mode.models.Elements.Poi')

---@class PoiZone : Poi
---@field zone Zone
---@field point_type PoiZone.Type
---@field point_index integer
local PoiZone = class("PoiZone", Poi)
PoiZone.__model_path = "Elements.Scorables.Zone.Poi"

---@enum PoiZone.Type
PoiZone.Type = {
    FromInsideLine = "FromInsideLine",
    FromOutsideLine = "FromOutsideLine",
    Center = "Center"
}

function PoiZone:initialize(point, zone, zone_obj_type, point_index)
    Poi.initialize(self, point)
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

---@param context EditorRoutine.Context
function PoiZone:onDelete(context)
    if self.point_type == PoiZone.Type.FromInsideLine then
        self.zone:getInsideLine():remove(self.point_index)
    elseif self.point_type == PoiZone.Type.FromOutsideLine then
        self.zone:getOutsideLine():remove(self.point_index)
    elseif self.point_type == PoiZone.Type.Center then
        ui.modalPopup(
            "Deleting zone",
            "Are you sure you want to delete the zone?",
            function()
                table.removeItem(context.course.scorables, self.zone)
            end
        )
    end
    ac.log("onDeleteZone")
end

return PoiZone
