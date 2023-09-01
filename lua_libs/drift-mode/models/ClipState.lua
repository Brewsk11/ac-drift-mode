local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipState : ClassBase
---@field clip Clip
---@field crossed boolean
---@field private hitPoint Point Point at which the clip was crossed
---@field private hitSpeedMult number
---@field private hitAngleMult number
---@field private hitRatioMult number
---@field private finalScore number Final score after multipliers `(maxScore * perf)`
---@field private finalMultiplier number Final multiplier
---@field private lastPoint Point To calculate where crossed
local ClipState = class("ClipState")

function ClipState:initialize(clip)
    self.clip = clip
    self.crossed = false
    self.hitPoint = nil
    self.hitAngleMult = nil
    self.hitSpeedMult = nil
    self.hitRatioMult = nil
    self.finalScore = nil
    self.finalMultiplier = nil
    self.lastPoint = nil
end

---Serializes to lightweight ClipStateData as ClipState should not be brokered.
---due to volume of `self.clip: Clip`
---@param self ClipState
---@return table
function ClipState:serialize()
    local data = {
        __class = "ClipStateData",
        clip = S.serialize(self.clip.name),
        maxPoints = S.serialize(self.clip.maxPoints),
        crossed = S.serialize(self.crossed),
        score = S.serialize(self:getScore()),
        performance = S.serialize(self:getPerformance()),
        multiplier = S.serialize(self:getMultiplier()),
        hitPoint = S.serialize(self.hitPoint),
        hitRatioMult = S.serialize(self:getRatio())
    }
    return data
end

---@param point Point
---@param drift_state DriftState
function ClipState:registerPosition(point, drift_state)
    -- If clip has been scored already, ignore
    if self.crossed then return end

    -- If last is nil then start by assigning last
    if self.lastPoint == nil then self.lastPoint = point; return end

    local res = vec2.intersect(
        self.lastPoint:flat(),
        point:flat(),
        self.clip.origin:flat(),
        self.clip:getEnd():flat()
    )

    if not res then -- Not hit, continue
       self.lastPoint = point
       return
    end

    self.hitAngleMult = drift_state.angle_mult
    self.hitSpeedMult = drift_state.speed_mult

    local end_to_hit = self.clip:getEnd():flat():distance(res)
    self.hitRatioMult = end_to_hit / self.clip.length

    -- Some magic to determine height of the hit
    local hit_segment_height =  point:value().y - self.lastPoint:value().y
    local hit_segment_ratio = point:flat():distance(res) / self.lastPoint:flat():distance(point:flat())
    local hit_height = point:value().y + hit_segment_height * hit_segment_ratio
    self.hitPoint = Point(vec3(res.x, hit_height, res.y))

    self.finalMultiplier = self.hitRatioMult * self.hitAngleMult * self.hitSpeedMult
    self.finalScore = self.finalMultiplier * self.clip.maxPoints
    self.crossed = true
end

function ClipState:getPerformance()
    if not self.crossed then return 0.0 end
    return self.hitSpeedMult * self.hitAngleMult
end

function ClipState:getMultiplier()
    if not self.crossed then return 0.0 end
    return self.finalMultiplier
end

function ClipState:getScore()
    if not self.crossed then return 0.0 end
    return self.finalScore
end

function ClipState:getRatio()
    if not self.crossed then return 0.0 end
    return self.hitRatioMult
end

local color_inactive = rgbm(0, 3, 2, 0.4)
local color_done = rgbm(0, 0, 3, 0.4)
local color_bad = rgb(1.5, 0, 1.5)
local color_good = rgb(0, 3, 0)

function ClipState:draw()
    local color = color_inactive
    if self.crossed then color = color_done end

    --- Rise the clip's arrow a little so it's not clipping
    local height_adjustment = vec3(0, 0.05, 0)

    render.debugArrow(self.clip.origin:value() + height_adjustment, self.clip:getEnd():value() + height_adjustment, 0.1, color)
    render.quad(
        self.clip.origin:value(),
        self.clip.origin:value() + vec3(0, 1, 0),
        self.clip.origin:value() - self.clip.direction * 0.4 + vec3(0, 1, 0),
        self.clip.origin:value() - self.clip.direction,
        color
    )

    if self.crossed then
        -- Ignore ratio in visualization as the clip distance can be gauged by point position
        local perf_without_ratio = self.hitAngleMult * self.hitSpeedMult

        local color_hit = color_bad * (1 - perf_without_ratio) + color_good * perf_without_ratio
        render.debugSphere(self.hitPoint:value(), 0.1, color_hit)
        render.debugLine(self.hitPoint:value(), self.hitPoint:value() + vec3(0, 1, 0), color_hit)
    end
end

local function test()
end
test()

return ClipState
