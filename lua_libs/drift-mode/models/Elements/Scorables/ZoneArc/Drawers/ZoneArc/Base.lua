local Drawer = require("drift-mode.models.Drawer")


---@class DrawerZoneArc : Drawer
---@field drawerInsideLine DrawerSegment
---@field drawerOutsideLine DrawerSegment
local DrawerZoneArc = class("DrawerZoneArc", Drawer)
DrawerZoneArc.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base"

function DrawerZoneArc:initialize()
end

---@param zone Zone
function DrawerZoneArc:draw(zone)
    for _, segment in zone:getInsideLine():segment():iter() do
        if self.drawerInsideLine then
            self.drawerInsideLine:draw(segment)
        end
    end

    for _, segment in zone:getOutsideLine():segment():iter() do
        if self.drawerOutsideLine then
            self.drawerOutsideLine:draw(segment)
        end
    end
end

return DrawerZoneArc
