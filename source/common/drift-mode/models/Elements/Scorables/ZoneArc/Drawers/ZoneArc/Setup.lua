local DrawerZoneArc = require('drift-mode.models.Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base')
local DrawerArcSetup = require("drift-mode.models.Common.Arc.Drawers.Setup")


---@class DrawerZoneArcSetup : DrawerZoneArc
local DrawerZoneArcSetup = class("DrawerZoneArcSetup", DrawerZoneArc)
DrawerZoneArcSetup.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Setup"

function DrawerZoneArcSetup:initialize()
    DrawerZoneArc.initialize(self)
    self.drawerArcInside = DrawerArcSetup()
    self.drawerArcOutside = DrawerArcSetup()
end

---@param zonearc ZoneArc
function DrawerZoneArcSetup:draw(zonearc)
    DrawerZoneArc.draw(self, zonearc)

    local zone_name_location = nil

    local gate = zonearc:getStartGate()
    if gate then
        zone_name_location = gate:getCenter():value()
    end

    if zone_name_location then
        render.debugText(zone_name_location + vec3(0, 0.5, 0), zonearc.name)
    end

    for _, handle in pairs(zonearc:gatherHandles()) do
        handle:draw()
    end
end

return DrawerZoneArcSetup
