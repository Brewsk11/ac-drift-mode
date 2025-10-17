local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")

---@class ZoneArcHandle : Handle
---@field zonearc ZoneArc
---@field point_type PoiZoneArc.Type
local ZoneArcHandle = class("ZoneArcHandle", Handle)
ZoneArcHandle.__model_path = "Elements.Scorables.ZoneArc.Handle"

---@enum PoiZoneArc.Type
ZoneArcHandle.Type = {
    ArcStart = "ArcStart",
    ArcEnd = "ArcEnd",
    ArcControl = "ArcControl",
    Center = "Center",
    WidthHandle = "WidthHandle"
}

function ZoneArcHandle:initialize(point, zone_arc, zone_obj_type)
    Handle.initialize(self, point, zone_arc)
    self.point_type = zone_obj_type
end

---@param new_pos vec3
function ZoneArcHandle:set(new_pos)
    local zonearc = self.element
    ---@cast zonearc ZoneArc
    if self.point_type == ZoneArcHandle.Type.Center then
        zonearc:setZoneArcPosition(Point(new_pos))
        return
    end

    if self.point_type == ZoneArcHandle.Type.WidthHandle then
        local arc = zonearc:getArc()
        local dist_from_center = new_pos:distance(arc:getCenter():value())
        if dist_from_center > arc:getRadius() then return end
        if dist_from_center < 2 then return end

        local new_width = arc:getRadius() - dist_from_center

        zonearc:setWidth(new_width)
    end

    local current_arc = zonearc:getArc()
    if current_arc == nil then return end

    if self.point_type == ZoneArcHandle.Type.ArcStart then
        zonearc:recalcArcFromTriplet(Point(new_pos), current_arc:getEndPoint(),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == ZoneArcHandle.Type.ArcEnd then
        zonearc:recalcArcFromTriplet(current_arc:getStartPoint(), Point(new_pos),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == ZoneArcHandle.Type.ArcControl then
        zonearc:recalcArcFromTriplet(current_arc:getStartPoint(), current_arc:getEndPoint(), Point(new_pos))
    end
end

function ZoneArcHandle:onDelete(context)
    table.removeItem(context.course.scorables, self.element)
end

return ZoneArcHandle
