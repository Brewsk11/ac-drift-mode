local Handle = require('drift-mode.models.Elements.Handle')

---@class ZoneHandle : Handle
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

function ZoneHandle:initialize(id, point, zone, zone_obj_type, point_index, drawer)
    Handle.initialize(self, id, point, zone, drawer)
    self.point_type = zone_obj_type
    self.point_index = point_index
end

---@param new_pos vec3
function ZoneHandle:set(new_pos)
    local zone = self.element
    ---@cast zone Zone
    if self.point_type == ZoneHandle.Type.Center then
        zone:setZonePosition(new_pos)
    else
        self.point:set(new_pos)
    end
end

---@param context EditorRoutine.Context
function ZoneHandle:onDelete(context)
    local zone = self.element
    ---@cast zone Zone
    if self.point_type == ZoneHandle.Type.FromInsideLine then
        zone:getInsideLine():remove(self.point_index)
    elseif self.point_type == ZoneHandle.Type.FromOutsideLine then
        zone:getOutsideLine():remove(self.point_index)
    elseif self.point_type == ZoneHandle.Type.Center then
        table.removeItem(context.course.scorables, zone) -- Change to course method call
        context.course:setDirty()
    end
end

return ZoneHandle
