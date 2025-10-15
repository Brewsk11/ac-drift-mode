local Handle = require('drift-mode.models.Elements.Handle')

---@class ZoneHandle : Handle
---@field zone Zone
---@field point_type ZoneHandle.Type
---@field point_index integer
local ZoneHandle = class("ZoneHandle", Handle)
ZoneHandle.__model_path = "Elements.Scorables.Zone.Handle"

---@enum ZoneHandle.Type
ZoneHandle.Type = {
    FromInsideLine = "FromInsideLine",
    FromOutsideLine = "FromOutsideLine",
    Center = "Center"
}

function ZoneHandle:initialize(point, zone, zone_obj_type, point_index)
    Handle.initialize(self, point)
    self.zone = zone
    self.point_type = zone_obj_type
    self.point_index = point_index
end

function ZoneHandle:set(new_pos)
    if self.point_type == ZoneHandle.Type.Center then
        self.zone:setZonePosition(new_pos)
    else
        self.point:set(new_pos)
    end
end

---@param context EditorRoutine.Context
function ZoneHandle:onDelete(context)
    if self.point_type == ZoneHandle.Type.FromInsideLine then
        self.zone:getInsideLine():remove(self.point_index)
    elseif self.point_type == ZoneHandle.Type.FromOutsideLine then
        self.zone:getOutsideLine():remove(self.point_index)
    elseif self.point_type == ZoneHandle.Type.Center then
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

return ZoneHandle
