local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Zone = require('drift-mode/models/Zone')

-- Track configration data

---@class TrackConfig
---@field name string Configuration name
---@field zones Zone[]
---@field clips Clip[]
---@field startLine Segment
---@field finishLine Segment
---@field startingPoint StartingPoint
---@field scoringRanges ScoringRanges
local TrackConfig = {}
TrackConfig.__index = TrackConfig

function TrackConfig.serialize(self)
    local data = {
        __class = "TrackConfig",
        name = S.serialize(self.name),
        zones = {},
        clips = {},
        startLine = S.serialize(self.startLine),
        finishLine  = S.serialize(self.finishLine),
        startingPoint = S.serialize(self.startingPoint),
        scoringRanges = S.serialize(self.scoringRanges)
    }

    for idx, zone in ipairs(self.zones) do
        data.zones[idx] = zone:serialize()
    end

    for idx, clipPoint in ipairs(self.clips) do
        data.clips[idx] = clipPoint:serialize()
    end

    return data
end

function TrackConfig.deserialize(data)
    Assert.Equal(data.__class, "TrackConfig", "Tried to deserialize wrong class")

    local obj = TrackConfig.new()

    local zones = {}
    for idx, zone in ipairs(data.zones) do
        zones[idx] = Zone.deserialize(zone)
    end

    -- 2.1.0 compatibility transfer
    --   Changed `clippingPoints` field name to `clips`
    if data.clippingPoints ~= nil then data.clips = data.clippingPoints end
    --   Added new field `scoringRanges`; if nil then fill default
    if S.deserialize(data.scoringRanges) == nil then
        data.scoringRanges = S.serialize(
            ScoringRanges.new(Range.new(15, 50), Range.new(5, 45))
        )
    end

    local clips = {}
    for idx, clipPoint in ipairs(data.clips) do
        clips[idx] = Clip.deserialize(clipPoint)
    end

    obj.name = S.deserialize(data.name)
    obj.zones = zones
    obj.clips = clips
    obj.startLine = S.deserialize(data.startLine)
    obj.finishLine = S.deserialize(data.finishLine)
    obj.startingPoint = S.deserialize(data.startingPoint)
    obj.scoringRanges = S.deserialize(data.scoringRanges)
    return obj
end

function TrackConfig.new(name, zones, clips, startLine, finishLine, startingPoint, scoringRanges)
    local self = setmetatable({}, TrackConfig)
    self.name = name or 'default'
    local _zones = zones or {}
    self.zones = _zones
    local _clips = clips or {}
    self.clips = _clips
    self.startLine = startLine
    self.finishLine = finishLine
    self.startingPoint = startingPoint
    self.scoringRanges = ScoringRanges.new(Range.new(15, 50), Range.new(5, 45))
    return self
end

function TrackConfig.drawSetup(self)
    for _, zone in ipairs(self.zones) do
        zone:drawSetup()
    end

    for _, clip in ipairs(self.clips) do
        clip:drawSetup()
    end

    if self.startingPoint then self.startingPoint:drawSetup() end
    if self.startLine then self.startLine:draw(rgbm(0, 3, 0, 1)) end
    if self.finishLine then self.finishLine:draw(rgbm(0, 0, 3, 1)) end
end

function TrackConfig.getNextZoneName(self)
    return "zone_" .. string.format('%03d', #self.zones + 1)
end

function TrackConfig.getNextClipName(self)
    return "clip_" .. string.format('%03d', #self.clips + 1)
end

local function test()
end
test()

return TrackConfig
