local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerClipSetup : DrawerClip
---@field draw_name boolean
---@field custom_label string
---@field color_origin rgbm
---@field color_pole rgbm
---@field color_arrow rgbm
local DrawerClipSetup = class("DrawerClipSetup", DrawerClip)

function DrawerClipSetup:initialize(draw_name, custom_label, color_origin, color_pole, color_arrow)
    self.draw_name = draw_name or true
    self.custom_label = custom_label
    self.color_origin = color_origin or rgbm(2, 0.5, 0.5, 1)
    self.color_pole = color_pole or rgbm(3, 3, 3, 3)
    self.color_arrow = color_arrow or rgbm(1.5, 0.5, 3, 3)
end

---@param clip Clip
function DrawerClipSetup:draw(clip)
    render.setDepthMode(render.DepthMode.Normal)

    clip.origin:draw(0.6, self.color_origin)
    render.debugArrow(clip.origin:value(), clip.origin:value() + clip.direction * clip.length, 0.1, self.color_arrow)
    render.debugLine(clip.origin:value(), clip.origin:value() + vec3(0, 0.2, 0), self.color_pole)

    if self.draw_name then
        render.debugText(
            clip.origin:value() + vec3(0, 0.3, 0),
            self.custom_label or clip.name
        )
    end
end

return DrawerClipSetup
