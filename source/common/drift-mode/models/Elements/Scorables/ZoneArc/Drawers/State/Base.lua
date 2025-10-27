local Drawer = require('drift-mode.models.Drawer')

---@class DrawerZoneArcState : Drawer
---@field drawerZoneArc DrawerZoneArc
local DrawerZoneArcState = class("DrawerZoneArcState", Drawer)
DrawerZoneArcState.__model_path = "Elements.Scorables.ZoneArc.Drawers.State.Base"

function DrawerZoneArcState:initialize()
end

---@param zonearc_state ZoneArcState
function DrawerZoneArcState:draw(zonearc_state)
    if self.drawerZoneArc then self.drawerZoneArc:draw(zonearc_state.zonearc) end
end

return DrawerZoneArcState
