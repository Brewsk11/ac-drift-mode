local Drawer = require('drift-mode/models/Drawer')

---@class DrawerZoneState : Drawer
---@field drawerZone DrawerZone
local DrawerZoneState = class("DrawerZoneState", Drawer)
DrawerZoneState.__model_path = "Drawers.DrawerZoneState"

function DrawerZoneState:initialize()
end

---@param zone_state ZoneState
function DrawerZoneState:draw(zone_state)
    if self.drawerZone then self.drawerZone:draw(zone_state.zone) end
end

return DrawerZoneState
