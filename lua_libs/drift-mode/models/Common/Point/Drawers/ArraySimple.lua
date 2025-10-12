local DrawerPointSimple = require('drift-mode.models.Common.Point.Drawers.Simple')
local DrawerPointArray = require('drift-mode.models.Common.Point.Drawers.BaseArray')

---@class DrawerPointArraySimple : DrawerPointArray
local DrawerPointArraySimple = class("DrawerPointGroupSimple", DrawerPointArray)
DrawerPointArraySimple.__model_path = "Common.Point.Drawers.ArraySimple"

function DrawerPointArraySimple:initialize(drawerPoint)
    self.drawerPoint = drawerPoint or DrawerPointSimple()
end

---@param point_array PointArray
function DrawerPointArraySimple:draw(point_array)
    DrawerPointArray.draw(self, point_array)
end

return DrawerPointArraySimple
