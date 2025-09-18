local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerPointGroupSimple : DrawerPointGroup
local DrawerPointGroupSimple = class("DrawerPointGroupSimple", DrawerPointGroup)
DrawerPointGroupSimple.__model_path = "Drawers.DrawerPointGroupSimple"

function DrawerPointGroupSimple:initialize(drawerPoint)
    self.drawerPoint = drawerPoint or DrawerPointSimple()
end

---@param point_group PointGroup
function DrawerPointGroupSimple:draw(point_group)
    DrawerPointGroup.draw(self, point_group)
end

return DrawerPointGroupSimple
