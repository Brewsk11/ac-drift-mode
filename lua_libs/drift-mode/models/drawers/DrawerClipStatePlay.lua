local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerClipStatePlay : DrawerClipState
---@field drawerClip DrawerClip
---@field protected drawerInactive DrawerClip
---@field protected drawerDone DrawerClip
local DrawerClipStatePlay = class("DrawerClipStatePlay", DrawerClipState)

function DrawerClipStatePlay:initialize()
    self.drawerInactive = DrawerClipPlay(rgbm(0, 3, 2, 0.4))
    self.drawerDone = DrawerClipPlay(rgbm(0, 0, 3, 0.4))

    self.drawerClip = self.drawerInactive

    -- TODO: Migrate to ClipStateHit?
    self.color_bad = rgb(1.5, 0, 1.5)
    self.color_good = rgb(0, 3, 0)

    self.height_collide = 1
    self.height_no_collide = 0.4
end

---@param clip_state ClipState
function DrawerClipStatePlay:draw(clip_state)
    render.setDepthMode(render.DepthMode.Normal)

    if clip_state.crossed then
        self.drawerClip = self.drawerDone
    else
        self.drawerClip = self.drawerInactive
    end

    if clip_state.clip:getCollide() then
        self.drawerClip.flag_height = self.height_collide
    else
        self.drawerClip.flag_height = self.height_no_collide
    end

    DrawerClipState.draw(self, clip_state)

    if clip_state.crossed then
        -- Ignore ratio in visualization as the clip distance can be gauged by point position
        local perf_without_ratio = clip_state.hitAngleMult * clip_state.hitSpeedMult

        local color_hit = self.color_bad * (1 - perf_without_ratio) + self.color_good * perf_without_ratio
        render.debugSphere(clip_state.hitPoint:value(), 0.1, color_hit)
        render.debugLine(clip_state.hitPoint:value(), clip_state.hitPoint:value() + vec3(0, 1, 0), color_hit)
    end
end

return DrawerClipStatePlay
