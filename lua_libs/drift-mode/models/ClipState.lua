local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipState
---@field clip Clip
---@field crossed boolean
---@field private hitPoint Point Point at which the clip was crossed
---@field private hitSpeedMult number
---@field private hitAngleMult number
---@field private hitRatioMult number
---@field private finalScore number Final score after multipliers `(maxScore * perf)`
---@field private finalPerformance number Final multiplier
---@field private lastPoint Point To calculate where crossed
local ClipState = {}
ClipState.__index = ClipState

---Serializes to lightweight ClipStateData as ClipState should not be brokered.
---due to volume of `self.clip: Clip`
---@param self ClipState
---@return table
function ClipState.serialize(self)
    local data = {
        __class = "ClipStateData",
        clip = S.serialize(self.clip.name),
        maxPoints = S.serialize(self.clip.maxPoints),
        crossed = S.serialize(self.crossed),
        score = S.serialize(self:getScore()),
        performance = S.serialize(self:getMultiplier()),
        hitPoint = S.serialize(self.hitPoint)
    }
    return data
end

function ClipState.new(clip)
    local self = setmetatable({}, ClipState)
    self.clip = clip
    self.crossed = false
    self.hitPoint = nil
    self.hitAngleMult = nil
    self.hitSpeedMult = nil
    self.hitRatioMult = nil
    self.finalScore = nil
    self.finalPerformance = nil
    self.lastPoint = nil
    return self
end

function ClipState:registerPosition(point, speed_mult, angle_mult)
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

    self.hitAngleMult = angle_mult
    self.hitSpeedMult = speed_mult

    local end_to_hit = self.clip:getEnd():flat():distance(res)
    self.hitRatioMult = end_to_hit / self.clip.length

    -- Some magic to determine height of the hit
    local hit_segment_height =  point:flat().y - self.lastPoint:flat().y
    local hit_segment_ratio = self.lastPoint:flat():distance(res) / self.lastPoint:flat():distance(point:flat())
    local hit_height = hit_segment_height * hit_segment_ratio
    self.hitPoint = Point.new("", vec3(res.x, hit_height, res.y))

    self.finalPerformance = self.hitRatioMult * self.hitAngleMult * self.hitSpeedMult
    self.finalScore = self.finalPerformance * self.clip.maxPoints
    self.crossed = true
end

function ClipState:getMultiplier()
    if not self.crossed then return 0.0 end
    return self.finalPerformance
end

function ClipState:getScore()
    if not self.crossed then return 0.0 end
    return self.finalScore
end

local function test()
end
test()

return ClipState
