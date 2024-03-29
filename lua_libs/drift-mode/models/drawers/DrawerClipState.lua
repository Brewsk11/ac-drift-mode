local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerClipState : Drawer
---@field drawerClip DrawerClip
local DrawerClipState = class("DrawerClipState", Drawer)

function DrawerClipState:initialize()
end

---@param clip_state ClipState
function DrawerClipState:draw(clip_state)
    if self.drawerClip then self.drawerClip:draw(clip_state.clip) end
end

return DrawerClipState
