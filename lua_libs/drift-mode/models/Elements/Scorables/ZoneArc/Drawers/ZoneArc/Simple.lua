local DrawerZone = require('drift-mode.models.Elements.Scorables.Zone.Drawers.Zone.Base')
local DrawerSegmentWall = require('drift-mode.models.Common.Segment.Drawers.Wall')

---@class DrawerZoneArcSimple : DrawerZone
local DrawerZoneArcSimple = class("DrawerZoneArcSimple", DrawerZone)
DrawerZoneArcSimple.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Simple"

function DrawerZoneArcSimple:initialize(wall_color)
    DrawerZone:initialize()
    self.drawerInsideLine = DrawerSegmentWall(wall_color, 0.1)
    self.drawerOutsideLine = DrawerSegmentWall(wall_color, 0.6)
end

---@param zone Zone
function DrawerZoneArcSimple:draw(zone)
    render.setDepthMode(render.DepthMode.ReadOnly)
    DrawerZone.draw(self, zone)
end

function DrawerZoneArcSimple:setOutsideWallHeight(value)
    self.drawerOutsideLine.height = value
end

return DrawerZoneArcSimple
