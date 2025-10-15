local Poi = require("drift-mode.models.Elements.Poi")
local Point = require("drift-mode.models.Common.Point.Point")

---@class PoiZoneArc : Poi
---@field zonearc ZoneArc
---@field point_type PoiZoneArc.Type
local PoiZoneArc = class("PoiZoneArc", Poi)
PoiZoneArc.__model_path = "Elements.Scorables.ZoneArc.Poi"

---@enum PoiZoneArc.Type
PoiZoneArc.Type = {
    ArcStart = "ArcStart",
    ArcEnd = "ArcEnd",
    ArcControl = "ArcControl",
    Center = "Center",
    WidthHandle = "WidthHandle"
}

function PoiZoneArc:initialize(point, zone_arc, zone_obj_type)
    Poi.initialize(self, point)
    self.zonearc = zone_arc
    self.point_type = zone_obj_type
end

---@param zonearc ZoneArc
---@return PoiZoneArc[]
function PoiZoneArc.gatherPois(zonearc)
    local pois = {}
    local arc = zonearc:getArc()
    if arc ~= nil then
        pois[#pois + 1] = PoiZoneArc(
            zonearc:getArc():getCenter(),
            zonearc,
            PoiZoneArc.Type.Center
        )

        pois[#pois + 1] = PoiZoneArc(
            arc:getStartPoint(),
            zonearc,
            PoiZoneArc.Type.ArcStart
        )

        pois[#pois + 1] = PoiZoneArc(
            arc:getEndPoint(),
            zonearc,
            PoiZoneArc.Type.ArcEnd
        )

        pois[#pois + 1] = PoiZoneArc(
            arc:getPointOnArc(0.5),
            zonearc,
            PoiZoneArc.Type.ArcControl
        )
    end
    return pois
end

function PoiZoneArc:set(new_pos)
    if self.point_type == PoiZoneArc.Type.Center then
        self.zonearc:getArc():setCenter(Point(new_pos))
        return
    end

    local current_arc = self.zonearc:getArc()
    if current_arc == nil then return end

    if self.point_type == PoiZoneArc.Type.ArcStart then
        self.zonearc:getArc():recalcFromTriplet(Point(new_pos), current_arc:getEndPoint(),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcEnd then
        self.zonearc:getArc():recalcFromTriplet(current_arc:getStartPoint(), Point(new_pos),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcControl then
        self.zonearc:getArc():recalcFromTriplet(current_arc:getStartPoint(), current_arc:getEndPoint(), Point(new_pos))
    end
end

function PoiZoneArc:onDelete(context)
    table.removeItem(context.course.scorables, self.zonearc)
end

return PoiZoneArc
