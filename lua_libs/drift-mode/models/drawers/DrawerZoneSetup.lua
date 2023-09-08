local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerZoneSetup : DrawerZone
---@field drawerOutsideLineWithCollision DrawerSegment
---@field drawerOutsideLineNoCollision DrawerSegment
local DrawerZoneSetup = class("DrawerZoneSetup", DrawerZone)

function DrawerZoneSetup:initialize()
    DrawerZone.initialize(self)
    self.drawerInsideLine = DrawerSegmentLine(rgbm(0.5, 2, 1.5, 3))
    self.drawerOutsideLineWithCollision = DrawerSegmentLine(rgbm(0.2, 0.1, 2.7, 3))
    self.drawerOutsideLineNoCollision = DrawerSegmentLine(  rgbm(0.4, 0.4, 2.2, 3))
    self.drawerOutsideLine = nil
end

---@param zone Zone
function DrawerZoneSetup:draw(zone)
    if zone:getCollide() then
        self.drawerOutsideLine = self.drawerOutsideLineWithCollision
    else
        self.drawerOutsideLine = self.drawerOutsideLineNoCollision
    end

    DrawerZone.draw(self, zone)

    local gate = zone:getStartGate()
    if gate then
        render.debugText(gate:getCenter() + vec3(0, 0.5, 0), zone.name)
    end
end

return DrawerZoneSetup
