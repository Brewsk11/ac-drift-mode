local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneScoringPoint
---@field point Point
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
local ZoneScoringPoint = {}
ZoneScoringPoint.__index = ZoneScoringPoint

local color_inactive = rgbm(1, 1, 1, 0.4)
local color_active = rgbm(0, 3, 0, 0.4)
local color_done = rgbm(0, 0, 3, 0.4)

function ZoneScoringPoint.new(point, speed_mult, angle_mult, ratio_mult)
    local self = setmetatable({}, ZoneScoringPoint)
    self.point = point
    self.speed_mult = speed_mult
    self.angle_mult = angle_mult
    self.ratio_mult = ratio_mult
    self.score_mult = speed_mult * angle_mult * ratio_mult
    return self
end

---@class ZoneState
---@field zone Zone
---@field scores ZoneScoringPoint[]
---@field started boolean
---@field finished boolean
---@field private finalMultiplier number
local ZoneState = {}
ZoneState.__index = ZoneState

-- Threshold for which the score will be returned as 0
-- With low samples it's most likely that the player only slightly touched the zone
ZoneState.MIN_SCORING_SAMPLES = 10

function ZoneState.new(zone)
    local self = setmetatable({}, ZoneState)
    self.zone = zone
    self.scoring_points = {}
    self.scores = {}
    self.started = false
    self.finished = false
    self.finalMultiplier = nil
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
      cross_line.tail:projected():distance(point:projected()) +
      cross_line.head:projected():distance(point:projected())
    local point_distance =
      cross_line.tail:projected():distance(point:projected())
    local ratio_mult = point_distance / cross_distance

    self.scores[#self.scores+1] = ZoneScoringPoint.new(point, speed_mult, angle_mult, ratio_mult)
    return ratio_mult
end

---@private
function ZoneState:calcMultiplier()
    if #self.scores == 0 then return 0 end

    local mult = 0
    for _, scorePoint in ipairs(self.scores) do mult = mult + scorePoint.score_mult end
    mult = mult / #self.scores

    return mult
end

function ZoneState:getMultiplier()
    if self:isFinished() then
        if self.finalMultiplier == nil then
            self.finalMultiplier = self:calcMultiplier()
        end
        return self.finalMultiplier
    end

    return self:calcMultiplier()
end

function ZoneState:getScore()
    if #self.scores < ZoneState.MIN_SCORING_SAMPLES then return 0 end
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
end

local function test()
end
test()

return RunState
