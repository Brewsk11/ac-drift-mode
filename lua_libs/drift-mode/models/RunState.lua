local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneScoringPoint
---@field point Point
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
---@field location number -- Location as a fraction of where the scored point lays in the zone
local ZoneScoringPoint = {}
ZoneScoringPoint.__index = ZoneScoringPoint

local color_inactive = rgbm(0, 3, 2, 0.4)
local color_active = rgbm(0, 3, 0, 0.4)
local color_done = rgbm(0, 0, 3, 0.4)

function ZoneScoringPoint.new(point, speed_mult, angle_mult, ratio_mult, location)
    local self = setmetatable({}, ZoneScoringPoint)
    self.point = point
    self.speed_mult = speed_mult
    self.angle_mult = angle_mult
    self.ratio_mult = ratio_mult
    self.score_mult = speed_mult * angle_mult * ratio_mult
    self.location = location
    return self
end

---@class ZoneState
---@field zone Zone
---@field scores ZoneScoringPoint[]
---@field started boolean
---@field finished boolean
---@field private finalPerformance number
local ZoneState = {}
ZoneState.__index = ZoneState

function ZoneState.new(zone)
    local self = setmetatable({}, ZoneState)
    self.zone = zone
    self.scoring_points = {}
    self.scores = {}
    self.started = false
    self.finished = false
    self.finalPerformance = nil
    return self
end

function ZoneState:registerPosition(point, speed_mult, angle_mult)
    -- If zone has already been finished, ignore call
    if self.finished then return end

    -- Check if the registering point belongs to the zone
    if not self.zone:isInZone(point) then
        -- If zone was started then end it
        if self.started then self.finished = true end
        return
    else
        self.started = true
    end

    -- Calculate the ratio multiplier
    -- inhit and outhit are not always colinear due to imperfect logic in shortestCrossline()..
    local cross_line = self.zone:shortestCrossline(point)

    local cross_distance =
      cross_line.segment.tail:projected():distance(point:projected()) +
      cross_line.segment.head:projected():distance(point:projected())
    local point_distance =
      cross_line.segment.tail:projected():distance(point:projected())
    local ratio_mult = point_distance / cross_distance

    -- Calculate how far the point is in the zone as a fraction
    -- dependent on which segments the shortest cross line has hit
    local out_segments = self.zone:getOutsideLine():count() - 1 -- There are 1 less segments than points in group
    local in_segments  = self.zone:getInsideLine():count() - 1
    local out_distance = cross_line.out_no / out_segments
    local in_distance = cross_line.in_no / in_segments
    local distance = (out_distance + in_distance) / 2 -- Simple average, there may be a better way

    -- Workaround for first segment
    -- If any of out or in segment hit number is 1, set the distance to 0
    -- as it's most likely player entered the zone exactly at the start.
    -- Setting the distance to 0 will allow to report 100% zone completion.
    if cross_line.in_no == 1 or cross_line.out_no == 1 then distance = 0 end

    self.scores[#self.scores+1] = ZoneScoringPoint.new(point, speed_mult, angle_mult, ratio_mult, distance)
    return ratio_mult
end

---@private
---@return number
function ZoneState:calcPerformance()
    if #self.scores == 0 then return 0 end

    local mult = 0
    for _, scorePoint in ipairs(self.scores) do mult = mult + scorePoint.score_mult end
    mult = mult / #self.scores

    return mult
end

---Get zone performance, i.e. a multiplier of speed, angle and distance to outside line.
---This leaves out the time spent in zone. For performance
---@return number
function ZoneState:getPerformance()
    if self:isFinished() then
        if self.finalPerformance == nil then
            self.finalPerformance = self:calcPerformance()
        end
        return self.finalPerformance
    end

    return self:calcPerformance()
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

function ZoneState:isActive()
    return self.started and not self.finished
end

function ZoneState:isFinished()
    return self.finished
end

function ZoneState:draw()
    local color = color_inactive
    if self:isActive() then color = color_active
    elseif self:isFinished() then color = color_done end

    self.zone:drawWall(color)
end

---@class RunState
---@field trackConfig TrackConfig
---@field zoneStates ZoneState[]
local RunState = {}
RunState.__index = RunState

function RunState.new(track_config)
    local self = setmetatable({}, RunState)
    self.trackConfig = track_config
    self.zoneStates = {}
    for _, zone in ipairs(self.trackConfig.zones) do
        self.zoneStates[#self.zoneStates+1] = ZoneState.new(zone)
    end
    return self
end

function RunState:registerPosition(point, speed_mult, angle_mult)
    local ratio = nil
    for _, zone in ipairs(self.zoneStates) do
        local res = zone:registerPosition(point, speed_mult, angle_mult)
        if res ~= nil then ratio = res end
    end
    return ratio
end

function RunState:getScore()
    local score = 0
    for _, zone_state in ipairs(self.zoneStates) do
        score = score + zone_state:getScore()
    end
    return score
end

function RunState:getPerformance()
    local mult = 0
    local zones_finished = 0
    for _, zone_state in ipairs(self.zoneStates) do
        if zone_state:isFinished() then
            mult = mult + zone_state:getMultiplier()
            zones_finished = zones_finished + 1
        end
    end
    if zones_finished == 0 then return 0 end
    mult = mult / zones_finished
    return mult
end

function RunState:draw()
    for _, zone_state in ipairs(self.zoneStates) do
        zone_state:draw()
    end

    if self.trackConfig.startLine then self.trackConfig.startLine:draw(rgbm(0, 3, 0, 1)) end
    if self.trackConfig.finishLine then self.trackConfig.finishLine:draw(rgbm(0, 0, 3, 1)) end
end

local function test()
end
test()

return RunState
