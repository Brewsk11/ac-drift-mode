local Assert = require('drift-mode.assert')
local EventSystem = require("drift-mode.eventsystem")
local Resources = require('drift-mode.Resources')

local ScoringObjectState = require("drift-mode.models.ScoringObjectState")
local Point = require("drift-mode.models.Point")

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
ClipState.__model_path = "ClipState"

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

---@param car_config CarConfig
---@param car ac.StateCar
---@param drift_state DriftState
---@return number|nil
function ClipState:registerCar(car_config, car, drift_state)
    local clip_scoring_point = Point(
        car.position + car.look * car_config.frontOffset +
        car.side * car_config.frontSpan * -drift_state.side_drifting
    )
    if clip_scoring_point:value():distance(self.clip.origin:value()) > self.clip:getLength() + 2 then
        return nil
    end

    local res = self:registerPosition(clip_scoring_point, drift_state)

    if res then
        EventSystem.emit(EventSystem.Signal.ScoringObjectStateChanged,
            {
                name = self.clip.name,
                payload = self
            })
    end

    return res
end

function ClipState:getName()
    return self.clip.name
end

function ClipState:getId()
    Assert.Error("Not implemented")
end

function ClipState:updatesFully()
    return true
end

-- Payload has to match ClipState:registerPosition()
function ClipState:consumeUpdate(payload)
    Assert.Error("ClipState updates fully by overwriting")
end

---@param point Point
---@param drift_state DriftState
function ClipState:registerPosition(point, drift_state)
    -- If clip has been scored already, ignore
    if self.crossed then return nil end

    -- If last is nil then start by assigning last
    if self.lastPoint == nil then
        self.lastPoint = point; return nil
    end

    local res = vec2.intersect(
        self.lastPoint:flat(),
        point:flat(),
        self.clip.origin:flat(),
        self.clip:getEnd():flat()
    )

    if not res then -- Not hit, continue
        self.lastPoint = point
        return nil
    end

    self.hitAngleMult = drift_state.angle_mult
    self.hitSpeedMult = drift_state.speed_mult

    local end_to_hit = self.clip:getEnd():flat():distance(res)
    self.hitRatioMult = end_to_hit / self.clip.length

    -- Some magic to determine height of the hit
    local hit_segment_height = point:value().y - self.lastPoint:value().y
    local hit_segment_ratio = point:flat():distance(res) / self.lastPoint:flat():distance(point:flat())
    local hit_height = point:value().y + hit_segment_height * hit_segment_ratio
    self.hitPoint = Point(vec3(res.x, hit_height, res.y))

    self.finalMultiplier = self.hitRatioMult * self.hitAngleMult * self.hitSpeedMult
    self.finalScore = self.finalMultiplier * self.clip.maxPoints
    self.crossed = true

    return self.hitRatioMult
end

---@param coord_transformer fun(point: Point): vec2
function ClipState:drawFlat(coord_transformer, scale)
    if self.hitPoint == nil then return end

    local point_color =
        Resources.Colors.ScoringObjectGood * self:getSpeed() +
        Resources.Colors.ScoringObjectBad * (1 - self:getSpeed())

    point_color.mult = 1

    local radius = 3 - self:getAngle() * 2.5

    ui.drawCircleFilled(
        coord_transformer(self.hitPoint),
        radius * scale,
        point_color)
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
