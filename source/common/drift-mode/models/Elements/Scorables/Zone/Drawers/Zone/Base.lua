local Drawer = require("drift-mode.models.Drawer")


---@class DrawerZone : Drawer
---@field drawerInsideLine DrawerSegment
---@field drawerOutsideLine DrawerSegment
local DrawerZone = class("DrawerZone", Drawer)
DrawerZone.__model_path = "Elements.Scorables.Zone.Drawers.Zone.Base"

function DrawerZone:initialize()
end

---@param zone Zone
function DrawerZone:draw(zone)
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

return DrawerZone
