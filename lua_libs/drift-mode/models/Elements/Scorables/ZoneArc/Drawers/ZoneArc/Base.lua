local Drawer = require("drift-mode.models.Drawer")


---@class DrawerZoneArc : Drawer
---@field drawerArcOutside DrawerArc
---@field drawerArcInside DrawerArc
local DrawerZoneArc = class("DrawerZoneArc", Drawer)
DrawerZoneArc.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base"

function DrawerZoneArc:initialize()
    Drawer:initialize()
end

---@param zonearc ZoneArc
function DrawerZoneArc:draw(zonearc)
    if self.drawerArcOutside then
        self.drawerArcOutside:draw(zonearc:getArc())
    end

    if self.drawerArcInside then
        self.drawerArcInside:draw(zonearc:getInsideArc())
    end

    -- TODO : insideline
end

return DrawerZoneArc
