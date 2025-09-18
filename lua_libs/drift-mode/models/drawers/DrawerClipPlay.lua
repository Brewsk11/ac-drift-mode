local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerClipPlay : DrawerClip
---@field color rgbm
local DrawerClipPlay = class("DrawerClipPlay", DrawerClip)
DrawerClipPlay.__model_path = "Drawers.DrawerClipPlay"

function DrawerClipPlay:initialize(color, flag_height)
    self.color = color or rgbm(1, 1, 1, 3)
    self.flag_height = flag_height or 1
end

---@param clip Clip
function DrawerClipPlay:draw(clip)
    render.setDepthMode(render.DepthMode.ReadOnly)

    --- Rise the clip's arrow a little so it's not clipping
    local height_adjustment = vec3(0, 0.05, 0)

    render.debugArrow(
        clip.origin:value() + height_adjustment,
        clip:getEnd():value() + height_adjustment,
        0.1,
        self.color)

    render.quad(
        clip.origin:value(),
        clip.origin:value() + vec3(0, self.flag_height, 0),
        clip.origin:value() - clip.direction * 0.5 + vec3(0, self.flag_height, 0),
        clip.origin:value() - clip.direction,
        self.color)
end

return DrawerClipPlay
