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

local function test()
end
test()

return ZoneScoringPoint
