local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerZoneSetup : DrawerZone
---@field drawerInsideLine DrawerSegment
---@field drawerOutsideLine DrawerSegment
local DrawerZoneSetup = class("DrawerZoneSetup", DrawerZone)

function DrawerZoneSetup:initialize()
    DrawerZone.initialize(self)
    self.drawerInsideLine = DrawerSegmentLine(rgbm(0.5, 2, 1.5, 3))
    self.drawerOutsideLine = DrawerSegmentLine(rgbm(1.5, 2, 0.5, 3))
end

---@param zone Zone
function DrawerZoneSetup:draw(zone)
    DrawerZone.draw(self, zone)

    local gate = zone:getStartGate()
    if gate then
        render.debugText(gate:getCenter() + vec3(0, 0.5, 0), zone.name)
    end
end

return DrawerZoneSetup
