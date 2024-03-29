local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerZoneState : Drawer
---@field drawerZone DrawerZone
local DrawerZoneState = class("DrawerZoneState", Drawer)

function DrawerZoneState:initialize()
end

---@param zone_state ZoneState
function DrawerZoneState:draw(zone_state)
    if self.drawerZone then self.drawerZone:draw(zone_state.zone) end
end

return DrawerZoneState
