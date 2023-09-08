local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerZoneStatePlay : DrawerZoneState
---@field drawerZone DrawerZone
---@field protected drawerInactive DrawerZone
---@field protected drawerActive DrawerZone
---@field protected drawerDone DrawerZone
local DrawerZoneStatePlay = class("DrawerZoneStatePlay", DrawerZoneState)

function DrawerZoneStatePlay:initialize(showZoneScorePoints)
    self.color_inactive = rgbm(0, 2, 1, 0.4)
    self.color_active = rgbm(0, 3, 0, 0.4)
    self.color_done = rgbm(0, 0, 3, 0.4)
    self.color_bad = rgbm(2, 0, 1, 1)
    self.color_good = rgbm(0, 3, 0, 1)
    self.color_outside = rgbm(3, 0, 0, 0.2)

    self.showZoneScorePoints = showZoneScorePoints or false

    self.drawerInactive = DrawerZonePlay(self.color_inactive)
    self.drawerActive = DrawerZonePlay(self.color_active)
    self.drawerDone = DrawerZonePlay(self.color_done)

    self.drawerZone = self.drawerInactive
end

---@param zone_state ZoneState
function DrawerZoneStatePlay:draw(zone_state)
    if zone_state:isActive() then
        self.drawerZone = self.drawerActive
    elseif zone_state:isDone() then
        self.drawerZone = self.drawerDone
    else
        self.drawerZone = self.drawerInactive
    end

    render.setDepthMode(render.DepthMode.Normal)
    DrawerZoneState.draw(self, zone_state)

    if not self.showZoneScorePoints then
        return
    end

    -- Draw at most N lines for performance reasons
    local N = 50
    local nth = 1
    while #zone_state.scores / nth > N do
        nth = nth + 1
    end

    for idx, scoring_point in ipairs(zone_state.scores) do
        local next_idx = idx + nth
        if next_idx > #zone_state.scores then break end -- Skip last point

        if idx % nth == 0 then
            local color = nil

            if not scoring_point.inside then
                color = self.color_outside
            else
                -- Ignore ratio in visualization as the distance from outside line can be gauged by point position
                local perf_without_ratio = scoring_point.speed_mult * scoring_point.angle_mult
                color = self.color_bad * (1 - perf_without_ratio) + self.color_good * perf_without_ratio
            end

            render.debugLine(
                scoring_point.point:value(),
                zone_state.scores[next_idx].point:value(),
                color
            )

            render.debugSphere(
                scoring_point.point:value(),
                0.1,
                color
            )
        end
    end
end

function DrawerZoneStatePlay:setShowZoneScorePoints(value)
    self.showZoneScorePoints = value
end

return DrawerZoneStatePlay
