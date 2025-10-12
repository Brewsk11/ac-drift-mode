local Drawer = require("drift-mode.models.Drawer")


---@class DrawerZoneArc : Drawer
---@field drawerInsideLine DrawerSegment
---@field drawerOutsideLine DrawerSegment
local DrawerZoneArc = class("DrawerZoneArc", Drawer)
DrawerZoneArc.__model_path = "Elements.Scorables.ZoneArc.Drawers.ZoneArc.Base"

function DrawerZoneArc:initialize()
end

---@param zone ZoneArc
function DrawerZoneArc:draw(zone)
    for _, segment in zone:getArc():toPointArray(8):segment(false):iter() do
        if self.drawerOutsideLine then
            self.drawerOutsideLine:draw(segment)
        end
    end

    -- TODO : insideline
end

return DrawerZoneArc
