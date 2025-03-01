local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Resources = require('drift-mode/Resources')

---@class DrawerZoneStatePlay : DrawerZoneState
---@field drawerZone DrawerZone
---@field protected drawerInactive DrawerZone
---@field protected drawerActive DrawerZone
---@field protected drawerDone DrawerZone
local DrawerZoneStatePlay = class("DrawerZoneStatePlay", DrawerZoneState)

function DrawerZoneStatePlay:initialize(showZoneScorePoints)
    self.color_inactive = Resources.Colors.ScoringObjectInactive
    self.color_active = Resources.Colors.ScoringObjectActive
    self.color_done = Resources.Colors.ScoringObjectDone
    self.color_bad = Resources.Colors.ScoringObjectBad
    self.color_good = Resources.Colors.ScoringObjectGood
    self.color_outside = Resources.Colors.ScoringObjectOutside

    self.showZoneScorePoints = showZoneScorePoints or false

    self.drawerInactive = DrawerZonePlay(self.color_inactive)
    self.drawerActive = DrawerZonePlay(self.color_active)
    self.drawerDone = DrawerZonePlay(self.color_done)

    self.drawerZone = self.drawerInactive
end

---@param zone_state ZoneState
function DrawerZoneStatePlay:draw(zone_state)
    render.setDepthMode(render.DepthMode.ReadOnly)

    if zone_state:isActive() then
        self.drawerZone = self.drawerActive
    elseif zone_state:isDone() then
        self.drawerZone = self.drawerDone
    else
        self.drawerZone = self.drawerInactive
    end

    if zone_state.zone:getCollide() then
        self.drawerZone:setOutsideWallHeight(1.2)
    else
        self.drawerZone:setOutsideWallHeight(0.6)
    end

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

            local dir = (zone_state.scores[next_idx].point:value() - scoring_point.point:value()):normalize()
            local normal = dir:clone():cross(vec3(0, 1, 0)):normalize()
            local width = 0.08

            render.quad(
                scoring_point.point:value() + vec3(0, 0.1, 0) + (normal * width / 2),
                zone_state.scores[next_idx].point:value() + vec3(0, 0.1, 0) + (normal * width / 2),
                zone_state.scores[next_idx].point:value() + vec3(0, 0.1, 0) - (normal * width / 2),
                scoring_point.point:value() + vec3(0, 0.1, 0) - (normal * width / 2),
                color
            )

            render.circle(
                scoring_point.point:value() + vec3(0, 0.1, 0),
                vec3(0, 1, 0),
                width,
                color
            )
        end
    end
end

function DrawerZoneStatePlay:setShowZoneScorePoints(value)
    self.showZoneScorePoints = value
end

return DrawerZoneStatePlay
