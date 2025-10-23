local EventSystem = require('drift-mode.EventSystem')
local Assert = require('drift-mode.Assert')
local Resources = require('drift-mode.Resources')

local ScorableState = require("drift-mode.models.Elements.Scorables.ScorableState")
local Point = require("drift-mode.models.Common.Point.Point")
local ZoneArcScoringPoint = require("drift-mode.models.Elements.Scorables.ZoneArc.ZoneArcScoringPoint")

---@class ZoneArcState : ScorableState
---@field zonearc ZoneArc
---@field scores ZoneArcScoringPoint[]
---@field started boolean
---@field finished boolean
---@field private performace number
local ZoneArcState = class("ZoneArcState", ScorableState)
ZoneArcState.__model_path = "Elements.Scorables.ZoneArc.ZoneArcState"

function ZoneArcState:initialize(zonearc)
    ScorableState.initialize(self)
    self.zonearc = zonearc
    self.scores = {}
    self.started = false
    self.finished = false
    self.performace = nil
    self:calculateFields()
end

function ZoneArcState:getName()
    return self.zonearc.name
end

function ZoneArcState:getId()
    Assert.Error("Not implemented")
end

---@param car_config CarConfig
---@param car ac.StateCar
---@param drift_state DriftState
---@return number|nil
function ZoneArcState:registerCar(car_config, car, drift_state)
    return nil
end

---@param point Point
---@param drift_state DriftState
---@return number
function ZoneArcState:registerPosition(point, drift_state, is_inside)
    return 0.0
end

function ZoneArcState:updatesFully()
    return false
end

-- Payload has to match ZoneArcState:registerPosition()
function ZoneArcState:consumeUpdate(payload)
    if payload.new_scoring_point ~= nil then
        self.scores[#self.scores + 1] = payload.new_scoring_point
        self:calculateFields()
    end
    if payload.finished ~= nil then
        self.finished = payload.finished
    end
end

function ZoneArcState:drawFlat(coord_transformer, scale)
    for _, score in ipairs(self.scores) do
        local point_color =
            Resources.Colors.ScorableGood * score.speed_mult +
            Resources.Colors.ScorableBad * (1 - score.speed_mult)
        if not score.inside then
            point_color = Resources.Colors.ScorableOutside
        end

        point_color.mult = 1

        ui.drawCircleFilled(
            coord_transformer(score.point),
            (3 - score.angle_mult * 2.5) * scale,
            point_color)
    end
end

---@private
function ZoneArcState:calculateFields()
    local score_mult = 0
    local speed_mult = 0
    local angle_mult = 0
    local depth_mult = 0
    if #self.scores ~= 0 then
        for _, scorePoint in ipairs(self.scores) do
            score_mult = score_mult + scorePoint.score_mult
            speed_mult = speed_mult + scorePoint.speed_mult
            angle_mult = angle_mult + scorePoint.angle_mult
            depth_mult = depth_mult + scorePoint.ratio_mult
        end
        score_mult = score_mult / #self.scores
        speed_mult = speed_mult / #self.scores
        angle_mult = angle_mult / #self.scores
        depth_mult = depth_mult / #self.scores
    end
    self.performace = score_mult
    self.speed = speed_mult
    self.angle = angle_mult
    self.depth = depth_mult
end

---@private
function ZoneArcState:setFinished(value)
    self.finished = value
    EventSystem:emit(EventSystem.Signal.ScorableStateChanged,
        {
            name = self.zonearc.name,
            payload = {
                finished = value
            }
        })
end

---Get zone performance, i.e. a multiplier of speed, angle and distance to outside line.
---This leaves out the time spent in zone. For final multiplier try `getMultiplier()`
---@return number
function ZoneArcState:getPerformance()
    return self.performace
end

function ZoneArcState:getMultiplier()
    if #self.scores == 0 then return 0 end
    return self:getPerformance() * self:getTimeInZone()
end

---Return a percentage of the distance of the zone where the earliest score
---has been recorded. For example, if the player enters the zone in the middle
---this shall return 0.5
---Return nil if the zone has not been scored.
---@return nil|number
function ZoneArcState:getWhereZoneEntered()
    if #self.scores == 0 then return nil end
    local earliest_scored = 1
    for _, score in ipairs(self.scores) do
        if score.location < earliest_scored then
            earliest_scored = score.location
        end
    end
    return earliest_scored
end

---Return a percentage of the distance of the zone where the last score
---has been recorded. For example, if the player exits the zone just before the end
---this shall return almost 1.0
---Return nil if the zone has not been scored.
---@return nil|number
function ZoneArcState:getWhereZoneExited()
    if #self.scores == 0 then return nil end
    local latest_scored = 0
    for _, score in ipairs(self.scores) do
        if score.location > latest_scored then
            latest_scored = score.location
        end
    end
    return latest_scored
end

---Return percentage of zone completion by the player
---Entering a zone at the start and exiting at the end will return 1.0
---If zone has not been scored yet, return nil
---@return nil|number
function ZoneArcState:getTimeInZone()
    if #self.scores == 0 then return nil end
    return self:getWhereZoneExited() - self:getWhereZoneEntered()
end

function ZoneArcState:getScore()
    return self:getMultiplier() * self.zonearc.maxPoints
end

function ZoneArcState:getSpeed()
    return self.speed
end

function ZoneArcState:getAngle()
    return self.angle
end

function ZoneArcState:getDepth()
    return self.depth
end

function ZoneArcState:getMaxScore()
    return self.zonearc.maxPoints
end

function ZoneArcState:isActive()
    return self.started and not self:isDone()
end

function ZoneArcState:isDone()
    return self.finished
end

local function test()
end
test()

return class.emmy(ZoneArcState, ZoneArcState.initialize)
