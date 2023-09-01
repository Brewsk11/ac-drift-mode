local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerZonePlay : DrawerZone
---@field drawerInsideLine DrawerSegment
---@field drawerOutsideLine DrawerSegment
local DrawerZonePlay = class("DrawerZonePlay", DrawerZone)

function DrawerZonePlay:initialize(wall_color)
    DrawerZone.initialize(self)
    self.drawerInsideLine = DrawerSegmentWall(wall_color, 0.2)
    self.drawerOutsideLine = DrawerSegmentWall(wall_color, 0.8)
end

---@param zone Zone
function DrawerZonePlay:draw(zone)
    render.setDepthMode(render.DepthMode.Normal)
    DrawerZone.draw(self, zone)
end

return DrawerZonePlay
