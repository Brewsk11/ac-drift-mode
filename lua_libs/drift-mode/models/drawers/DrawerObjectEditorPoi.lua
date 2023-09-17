local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerObjectEditorPoi : Drawer
---@field drawerPoint DrawerPoint[]?
local DrawerObjectEditorPoi = class("DrawerObjectEditorPoi", Drawer)

function DrawerObjectEditorPoi:initialize(drawerPoint)
    self.drawerPoint = drawerPoint or DrawerPointSimple()
end

---@param obj ObjectEditorPoi[]
function DrawerObjectEditorPoi:draw(obj)
    if self.drawerPoint then
        for _, poi in ipairs(obj) do
            self.drawerPoint:draw(poi.point)
        end
    end
end

return DrawerObjectEditorPoi
