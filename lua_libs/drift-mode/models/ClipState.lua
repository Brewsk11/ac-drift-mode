local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipState : ScoringObjectState
---@field clip Clip
---@field private hitPoint Point Point at which the clip was crossed
---@field private hitSpeedMult number
---@field private hitAngleMult number
---@field private hitRatioMult number
---@field private finalScore number Final score after multipliers `(maxScore * perf)`
---@field private finalMultiplier number Final multiplier
---@field private lastPoint Point To calculate where crossed
local ClipState = class("ClipState", ScoringObjectState)

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
function ClipState:__serialize()
    local data = {
        __class = "ClipStateData",
        name = S.serialize(self.clip.name),
        done = S.serialize(self:isDone()),
        score = S.serialize(self:getScore()),
        max_score = S.serialize(self.clip.maxPoints),
        speed = S.serialize(self:getSpeed()),
        angle = S.serialize(self:getAngle()),
        depth = S.serialize(self:getDepth()),

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

function ClipState:getSpeed()
    if not self.crossed then return 0.0 end
    return self.hitSpeedMult
end

function ClipState:getAngle()
    if not self.crossed then return 0.0 end
    return self.hitAngleMult
end

function ClipState:getDepth()
    if not self.crossed then return 0.0 end
    return self.hitRatioMult
end

function ClipState:getMaxScore()
    return self.clip.maxPoints
end

function ClipState:getRatio()
    if not self.crossed then return 0.0 end
    return self.hitRatioMult
end

function ClipState:isDone()
    return self.crossed
end

local function test()
end
test()

return ClipState
