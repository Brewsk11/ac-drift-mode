local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")

---@class ZoneArcHandle : Handle
---@field zonearc ZoneArc
---@field point_type PoiZoneArc.Type
local PoiZoneArc = class("PoiZoneArc", Handle)
PoiZoneArc.__model_path = "Elements.Scorables.ZoneArc.Handle"

---@enum PoiZoneArc.Type
PoiZoneArc.Type = {
    ArcStart = "ArcStart",
    ArcEnd = "ArcEnd",
    ArcControl = "ArcControl",
    Center = "Center",
    WidthHandle = "WidthHandle"
}

function PoiZoneArc:initialize(point, zone_arc, zone_obj_type)
    Handle.initialize(self, point)
    self.zonearc = zone_arc
    self.point_type = zone_obj_type
end

---@param new_pos vec3
function PoiZoneArc:set(new_pos)
    if self.point_type == PoiZoneArc.Type.Center then
        self.zonearc:setZoneArcPosition(Point(new_pos))
        return
    end

    if self.point_type == PoiZoneArc.Type.WidthHandle then
        local arc = self.zonearc:getArc()
        local dist_from_center = new_pos:distance(arc:getCenter():value())
        if dist_from_center > arc:getRadius() then return end
        if dist_from_center < 2 then return end

        local new_width = arc:getRadius() - dist_from_center

        self.zonearc:setWidth(new_width)
    end

    local current_arc = self.zonearc:getArc()
    if current_arc == nil then return end

    if self.point_type == PoiZoneArc.Type.ArcStart then
        self.zonearc:recalcArcFromTriplet(Point(new_pos), current_arc:getEndPoint(),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcEnd then
        self.zonearc:recalcArcFromTriplet(current_arc:getStartPoint(), Point(new_pos),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcControl then
        self.zonearc:recalcArcFromTriplet(current_arc:getStartPoint(), current_arc:getEndPoint(), Point(new_pos))
    end
end

function PoiZoneArc:onDelete(context)
    table.removeItem(context.course.scorables, self.zonearc)
end

return PoiZoneArc
