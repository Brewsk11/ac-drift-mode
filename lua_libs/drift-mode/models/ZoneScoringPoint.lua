local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneScoringPoint : ClassBase
---@field point Point
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
---@field location number -- Location as a fraction of where the scored point lays in the zone
---@field inside boolean -- Outside points are possible for buffering continuity when player left the zone only slightly
local ZoneScoringPoint = class("ZoneScoringPoint")

function ZoneScoringPoint:initialize(point, speed_mult, angle_mult, ratio_mult, location, inside)
    self.point = point
    self.speed_mult = speed_mult
    self.angle_mult = angle_mult
    self.ratio_mult = ratio_mult
    self.score_mult = speed_mult * angle_mult * ratio_mult
    self.location = location
    self.inside = inside
end

local function test()
end
test()

return ZoneScoringPoint
