local DrawerZoneArc = require('drift-mode.models.Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base')
local DrawerArcSimple = require("drift-mode.models.Common.Arc.Drawers.Simple")


---@class DrawerZoneArcSimple : DrawerZoneArc
local DrawerZoneArcSimple = class("DrawerZoneArcSimple", DrawerZoneArc)
DrawerZoneArcSimple.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Simple"

function DrawerZoneArcSimple:initialize(wall_color)
    DrawerZoneArc.initialize(self)
    self.drawerArcInside = DrawerArcSimple(wall_color, 0.1)
    self.drawerArcOutside = DrawerArcSimple(wall_color, 0.6)
end

---@param zonearc ZoneArc
function DrawerZoneArcSimple:draw(zonearc)
    render.setDepthMode(render.DepthMode.ReadOnly)
    DrawerZoneArc.draw(self, zonearc)
end

function DrawerZoneArcSimple:setOutsideWallHeight(value)
    self.drawerArcOutside.drawerSegment.height = value
end

return DrawerZoneArcSimple
