local DrawerZone = require('drift-mode.models.Elements.Scorables.Zone.Drawers.Zone.Base')
local DrawerSegmentWall = require('drift-mode.models.Common.Segment.Drawers.Wall')

---@class DrawerZonePlay : DrawerZone
local DrawerZonePlay = class("DrawerZonePlay", DrawerZone)
DrawerZonePlay.__model_path = "Elements.Scorables.Zone.Drawers.Zone.Simple"

function DrawerZonePlay:initialize(wall_color)
    DrawerZone.initialize(self)
    self.drawerInsideLine = DrawerSegmentWall(wall_color, 0.1)
    self.drawerOutsideLine = DrawerSegmentWall(wall_color, 0.6)
end

---@param zone Zone
function DrawerZonePlay:draw(zone)
    render.setDepthMode(render.DepthMode.ReadOnly)
    DrawerZone.draw(self, zone)
end

function DrawerZonePlay:setOutsideWallHeight(value)
    self.drawerOutsideLine.height = value
end

return DrawerZonePlay
