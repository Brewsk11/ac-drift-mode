local Resources = require('drift-mode.Resources')

local DrawerZoneState = require('drift-mode.models.Elements.Scorables.Zone.Drawers.State.Base')
local DrawerZonePlay = require('drift-mode.models.Elements.Scorables.Zone.Drawers.Zone.Simple')

---@class DrawerZoneArcStatePlay : DrawerZoneState
---@field drawerZone DrawerZoneArc
---@field protected drawerInactive DrawerZoneArc
---@field protected drawerActive DrawerZoneArc
---@field protected drawerDone DrawerZoneArc
local DrawerZoneArcStatePlay = class("DrawerZoneArcStatePlay", DrawerZoneState)
DrawerZoneArcStatePlay.__model_path = "Elements.Scorables.ZoneArc.Drawers.State.Simple"

function DrawerZoneArcStatePlay:initialize(showZoneScorePoints)
    DrawerZoneState:initialize()
end

---@param zone_state ZoneState
function DrawerZoneArcStatePlay:draw(zone_state)

end

function DrawerZoneArcStatePlay:setShowZoneScorePoints(value)
    self.showZoneScorePoints = value
end

return DrawerZoneArcStatePlay
