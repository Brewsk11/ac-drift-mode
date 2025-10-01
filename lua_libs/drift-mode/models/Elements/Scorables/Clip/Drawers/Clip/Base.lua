local Drawer = require('drift-mode.models.Drawer')

---@class DrawerClip : Drawer
local DrawerClip = class("DrawerClip", Drawer)
DrawerClip.__model_path = "Elements.Scorables.Clip.Drawers.Clip.Base"

function DrawerClip:initialize()
end

---@param clip Clip
function DrawerClip:draw(clip)
end

return DrawerClip
