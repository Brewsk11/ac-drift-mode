local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPointGroup : Drawer
---@field drawerPoint DrawerPoint
local DrawerPointGroup = class("DrawerPointGroup", Drawer)

function DrawerPointGroup:initialize()
end

---@param point_group PointGroup
function DrawerPointGroup:draw(point_group)
    if self.drawerPoint then
        for _, point in point_group:iter() do
            self.drawerPoint:draw(point)
        end
    end
end

return DrawerPointGroup
