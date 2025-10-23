local EventSystem = require('drift-mode.EventSystem')
local Assert = require('drift-mode.Assert')
local Resources = require('drift-mode.Resources')

local ScorableState = require("drift-mode.models.Elements.Scorables.ScorableState")
local Point = require("drift-mode.models.Common.Point.Point")
local ZoneScoringPoint = require("drift-mode.models.Elements.Scorables.Zone.ZoneScoringPoint")

---@class ZoneState : ScorableState
---@field zone Zone
---@field scores ZoneScoringPoint[]
---@field started boolean
---@field finished boolean
---@field private performace number
local ZoneState = class("ZoneState", ScorableState)
ZoneState.__model_path = "Elements.Scorables.Zone.ZoneState"

function ZoneState:initialize(zone)
    self.zone = zone
    self.scores = {}
    self.started = false
    self.finished = false
    self.performace = nil
    self:calculateFields()
end

function ZoneState:getName()
    return self.zone.name
end

function ZoneState:getId()
    Assert.Error("Not implemented")
end

---@param car_config CarConfig
---@param car ac.StateCar
---@param drift_state DriftState
---@return number|nil
function ZoneState:registerCar(car_config, car, drift_state)
    -- If zone has already been finished, ignore call
    if self:isDone() then return nil end

    local zone_scoring_point = Point(car.position - car.look * car_config.rearOffset +
        car.side * drift_state.shared_data.side_drifting * car_config.rearSpan)

    -- Check if the registering point belongs to the zone
    if not self.zone:isInZone(zone_scoring_point) then
        -- If zone was started then check if center point
        -- is still in for small buffer
        if self.started then
            local rear_bumper_center = Point(car.position - car.look * car_config.rearOffset)
            if not self.zone:isInZone(rear_bumper_center) then
                self:setFinished(true)
                return nil
            else
                return self:registerPosition(zone_scoring_point, drift_state, false)
            end
        else
            return nil
        end
    else
        self.started = true
    end

    return self:registerPosition(zone_scoring_point, drift_state, true)
end

---@param point Point
---@param drift_state DriftState
---@return number
function ZoneState:registerPosition(point, drift_state, is_inside)
    -- Calculate the ratio multiplier
    -- inhit and outhit are not always colinear due to imperfect logic in shortestCrossline()..
    local cross_line = self.zone:shortestCrossline(point)

    -- In limited number of rays there may not be a hit for a valid point inside the zone
    -- In such case for now unfortunatelly we'll assume the score did not happen
    if cross_line.segment == nil then
        ac.warn("Didn't find a crossline for valid point!"); return 0.0
    end

    local ratio_mult = 0.0
    -- In case of calculating for point in safety buffer (when player slightly ran outside
    -- but we keep scoring 0 to allow coming back to the zone)
    if is_inside then
        local cross_distance =
            cross_line.segment:getTail():projected():distance(point:projected()) +
            cross_line.segment:getHead():projected():distance(point:projected())
        local point_distance =
            cross_line.segment:getTail():projected():distance(point:projected())
        ratio_mult = point_distance / cross_distance
    end

    -- Calculate how far the point is in the zone as a fraction
    -- dependent on which segments the shortest cross line has hit
    local out_segments = self.zone:getOutsideLine():count() - 1 -- There are 1 less segments than points in group
    local in_segments  = self.zone:getInsideLine():count() - 1
    local out_distance = cross_line.out_no / out_segments
    local in_distance  = cross_line.in_no / in_segments
    local distance     = (out_distance + in_distance) / 2 -- Simple average, there may be a better way

    -- Workaround for first segment
    -- If any of out or in segment hit number is 1, set the distance to 0
    -- as it's most likely player entered the zone exactly at the start.
    -- Setting the distance to 0 will allow to report 100% zone completion.
    if cross_line.in_no == 1 or cross_line.out_no == 1 then distance = 0 end

    self.scores[#self.scores + 1] = ZoneScoringPoint(
        point,
        drift_state.shared_data.speed_mult,
        drift_state.shared_data.angle_mult,
        ratio_mult,
        distance,
        is_inside
    )

    self:calculateFields()

    EventSystem:emit(EventSystem.Signal.ScorableStateChanged,
        {
            name = self.zone.name,
            payload = {
                new_scoring_point = self.scores[#self.scores]
            }
        })

    return ratio_mult
end

function ZoneState:updatesFully()
    return false
end

-- Payload has to match ZoneState:registerPosition()
function ZoneState:consumeUpdate(payload)
    if payload.new_scoring_point ~= nil then
        self.scores[#self.scores + 1] = payload.new_scoring_point
        self:calculateFields()
    end
    if payload.finished ~= nil then
        self.finished = payload.finished
    end
end

function ZoneState:drawFlat(coord_transformer, scale)
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
function ZoneState:calculateFields()
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
function ZoneState:setFinished(value)
    self.finished = value
    EventSystem:emit(EventSystem.Signal.ScorableStateChanged,
        {
            name = self.zone.name,
            payload = {
                finished = value
            }
        })
end

---Get zone performance, i.e. a multiplier of speed, angle and distance to outside line.
---This leaves out the time spent in zone. For final multiplier try `getMultiplier()`
---@return number
function ZoneState:getPerformance()
    return self.performace
end

function ZoneState:getMultiplier()
    if #self.scores == 0 then return 0 end
    return self:getPerformance() * self:getTimeInZone()
end

---Return a percentage of the distance of the zone where the earliest score
---has been recorded. For example, if the player enters the zone in the middle
---this shall return 0.5
---Return nil if the zone has not been scored.
---@return nil|number
function ZoneState:getWhereZoneEntered()
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
function ZoneState:getWhereZoneExited()
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
function ZoneState:getTimeInZone()
    if #self.scores == 0 then return nil end
    return self:getWhereZoneExited() - self:getWhereZoneEntered()
end

function ZoneState:getScore()
    return self:getMultiplier() * self.zone.maxPoints
end

function ZoneState:getSpeed()
    return self.speed
end

function ZoneState:getAngle()
    return self.angle
end

function ZoneState:getDepth()
    return self.depth
end

function ZoneState:getMaxScore()
    return self.zone.maxPoints
end

function ZoneState:isActive()
    return self.started and not self:isDone()
end

function ZoneState:isDone()
    return self.finished
end

local function test()
end
test()

return ZoneState
