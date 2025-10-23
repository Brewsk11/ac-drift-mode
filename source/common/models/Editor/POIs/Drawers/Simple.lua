local Drawer = require('drift-mode.models.Drawer')
local DrawerPointSimple = require('drift-mode.models.Common.Point.Drawers.Simple')

---@class DrawerObjectEditorPoi : Drawer
---@field drawerPoint DrawerPoint[]?
local DrawerObjectEditorPoi = class("DrawerObjectEditorPoi", Drawer)
DrawerObjectEditorPoi.__model_path = "Editor.POIs.Drawers.Simple"

function DrawerObjectEditorPoi:initialize(drawerPoint)
    self.drawerPoint = drawerPoint or DrawerPointSimple()
end

---@param obj Handle[]
function DrawerObjectEditorPoi:draw(obj)
    if self.drawerPoint then
        for _, poi in ipairs(obj) do
            self.drawerPoint:draw(poi.point)
        end
    end
end

return DrawerObjectEditorPoi
