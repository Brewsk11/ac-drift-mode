local DrawerPointSimple = require('drift-mode.models.Common.Point.Drawers.Simple')
local DrawerPointGroup = require('drift-mode.models.Common.Point.Drawers.BaseGroup')

---@class DrawerPointGroupSimple : DrawerPointGroup
local DrawerPointGroupSimple = class("DrawerPointGroupSimple", DrawerPointGroup)
DrawerPointGroupSimple.__model_path = "Common.Point.Drawers.GroupSimple"

function DrawerPointGroupSimple:initialize(drawerPoint)
    self.drawerPoint = drawerPoint or DrawerPointSimple()
end

---@param point_group PointGroup
function DrawerPointGroupSimple:draw(point_group)
    DrawerPointGroup.draw(self, point_group)
end

return DrawerPointGroupSimple
