local DrawerZoneArc = require('drift-mode.models.Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base')
local DrawerSegmentLine = require('drift-mode.models.Common.Segment.Drawers.Line')

---@class DrawerZoneArcSetup : DrawerZoneArc
---@field drawerOutsideLineWithCollision DrawerSegment
---@field drawerOutsideLineNoCollision DrawerSegment
local DrawerZoneArcSetup = class("DrawerZoneArcSetup", DrawerZoneArc)
DrawerZoneArcSetup.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Setup"

function DrawerZoneArcSetup:initialize()
    DrawerZoneArc.initialize(self)
    self.drawerInsideLine = DrawerSegmentLine(rgbm(0.5, 2, 1.5, 3))
    self.drawerOutsideLineWithCollision = DrawerSegmentLine(rgbm(0.2, 0.1, 2.7, 3))
    self.drawerOutsideLineNoCollision = DrawerSegmentLine(rgbm(0.4, 0.4, 2.2, 3))
    self.drawerOutsideLine = nil
end

---@param zone ZoneArc
function DrawerZoneArcSetup:draw(zone)
    if zone:getCollide() then
        self.drawerOutsideLine = self.drawerOutsideLineWithCollision
    else
        self.drawerOutsideLine = self.drawerOutsideLineNoCollision
    end

    DrawerZoneArc.draw(self, zone)

    local zone_name_location = nil

    local gate = zone:getStartGate()
    if gate then
        zone_name_location = gate:getCenter():value()
    end

    if zone_name_location then
        render.debugText(zone_name_location + vec3(0, 0.5, 0), zone.name)
    end
end

return DrawerZoneArcSetup
