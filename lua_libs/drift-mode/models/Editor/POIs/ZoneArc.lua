local ObjectEditorPoi = require('drift-mode.models.Editor.POIs.Base')
local Point = require("drift-mode.models.Common.Point.Point")
local Arc = require("drift-mode.models.Common.Arc.Arc")

---@class PoiZoneArc : ObjectEditorPoi
---@field zone_arc ZoneArc
---@field point_type PoiZoneArc.Type
local PoiZoneArc = class("PoiZoneArc", ObjectEditorPoi)
PoiZoneArc.__model_path = "Editor.POIs.ZoneArc"

---@enum PoiZoneArc.Type
PoiZoneArc.Type = {
    ArcStart = "ArcStart",
    ArcEnd = "ArcEnd",
    ArcControl = "ArcControl",
    Center = "Center",
    WidthHandle = "WidthHandle"
}

function PoiZoneArc:initialize(point, zone_arc, zone_obj_type)
    ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.ZoneArc)
    self.zone_arc = zone_arc
    self.point_type = zone_obj_type
end

function PoiZoneArc:set(new_pos)
    if self.point_type == PoiZoneArc.Type.Center then
        self.zone_arc:getArc():setCenter(Point(new_pos))
        return
    end

    local current_arc = self.zone_arc:getArc()
    if current_arc == nil then return end

    if self.point_type == PoiZoneArc.Type.ArcStart then
        self.zone_arc:getArc():recalcFromTriplet(Point(new_pos), current_arc:getEndPoint(),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcEnd then
        self.zone_arc:getArc():recalcFromTriplet(current_arc:getStartPoint(), Point(new_pos),
            current_arc:getPointOnArc(0.5))
    elseif self.point_type == PoiZoneArc.Type.ArcControl then
        self.zone_arc:getArc():recalcFromTriplet(current_arc:getStartPoint(), current_arc:getEndPoint(), Point(new_pos))
    end
end

return PoiZoneArc
