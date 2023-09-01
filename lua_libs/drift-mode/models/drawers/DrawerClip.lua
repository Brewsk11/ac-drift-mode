local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerClip : Drawer
local DrawerClip = class("DrawerClip", Drawer)

function DrawerClip:initialize()
end

---@param clip Clip
function DrawerClip:draw(clip)
end

return DrawerClip
