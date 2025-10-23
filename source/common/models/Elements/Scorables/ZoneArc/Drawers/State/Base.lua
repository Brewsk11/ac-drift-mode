local Drawer = require('drift-mode.models.Drawer')

---@class DrawerZoneArcState : Drawer
---@field drawerZoneArc DrawerZoneArc
local DrawerZoneArcState = class("DrawerZoneArcState", Drawer)
DrawerZoneArcState.__model_path = "Elements.Scorables.ZoneArc.Drawers.State.Base"

function DrawerZoneArcState:initialize()
end

---@param zone_state ZoneState
function DrawerZoneArcState:draw(zone_state)
    if self.drawerZoneArc then self.drawerZoneArc:draw(zone_state.zone) end
end

return DrawerZoneArcState
