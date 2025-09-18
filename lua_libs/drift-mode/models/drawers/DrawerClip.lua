local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Drawer = require('drift-mode/models/Drawers/Drawer')

---@class DrawerClip : Drawer
local DrawerClip = class("DrawerClip", Drawer)
DrawerClip.__model_path = "Drawers.DrawerClip"

function DrawerClip:initialize()
end

---@param clip Clip
function DrawerClip:draw(clip)
end

return DrawerClip
