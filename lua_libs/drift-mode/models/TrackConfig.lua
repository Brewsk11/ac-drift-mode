local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Zone = require('drift-mode/models/Zone')

-- Track configration data

---@class TrackConfig
---@field name string Configuration name
---@field zones Zone[]
---@field clippingPoints ClippingPoint[]
---@field startLine Segment
---@field finishLine Segment
---@field startingPoint StartingPoint
local TrackConfig = {}
TrackConfig.__index = TrackConfig

function TrackConfig.serialize(self)
    local data = {
        __class = "TrackConfig",
        name = S.serialize(self.name),
        zones = {},
        clippingPoints = {},
        startLine = S.serialize(self.startLine),
        finishLine  = S.serialize(self.finishLine),
        startingPoint = S.serialize(self.startingPoint)
    }

    for idx, zone in ipairs(self.zones) do
        data.zones[idx] = zone:serialize()
    end

    for idx, clipPoint in ipairs(self.clippingPoints) do
        data.clippingPoints[idx] = clipPoint:serialize()
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

    local clippingPoints = {}
    for idx, clipPoint in ipairs(data.clippingPoints) do
        clippingPoints[idx] = ClippingPoint.deserialize(clipPoint)
    end

    obj.name = S.deserialize(data.name)
    obj.zones = zones
    obj.clippingPoints = clippingPoints
    obj.startLine = S.deserialize(data.startLine)
    obj.finishLine = S.deserialize(data.finishLine)
    obj.startingPoint = S.deserialize(data.startingPoint)
    return obj
end

function TrackConfig.new(name, zones, clippingPoints, startLine, finishLine, startingPoint)
    local self = setmetatable({}, TrackConfig)
    self.name = name or 'default'
    local _zones = zones or {}
    self.zones = _zones
    local _clippingPoints = clippingPoints or {}
    self.clippingPoints = _clippingPoints
    self.startLine = startLine
    self.finishLine = finishLine
    self.startingPoint = startingPoint
    return self
end

function TrackConfig.drawSetup(self)
    for _, zone in ipairs(self.zones) do
      zone:drawSetup()
    end

    if self.startingPoint then self.startingPoint:drawSetup() end
    if self.startLine then self.startLine:draw(rgbm(0, 3, 0, 1)) end
    if self.finishLine then self.finishLine:draw(rgbm(0, 0, 3, 1)) end
end

function TrackConfig.getNextZoneName(self)
    return "zone_" .. string.format('%03d', #self.zones + 1)
end

function TrackConfig.getNextClipName(self)
    return "clip_" .. string.format('%03d', #self.clippingPoints + 1)
end

local function test()
end
test()

return TrackConfig
