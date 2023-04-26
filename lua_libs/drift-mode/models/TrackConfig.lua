local Assert = require('drift-mode/assert')
local Zone = require('drift-mode/models/Zone')

-- Track configration data

---@class TrackConfig
---@field zones Zone[]
---@field clippingPoints ClippingPoint[]
local TrackConfig = {}
TrackConfig.__index = TrackConfig

function TrackConfig.serialize(self)
    local data = {
        __class = "TrackConfig",
        zones = {},
        clippingPoints = {}
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

    obj.zones = zones
    obj.clippingPoints = clippingPoints
    return obj
end

function TrackConfig.new(zones, clippingPoints)
    local self = setmetatable({}, TrackConfig)
    local _zones = zones or {}
    self.zones = _zones
    local _clippingPoints = clippingPoints or {}
    self.clippingPoints = _clippingPoints
    return self
end

function TrackConfig.draw(self)
    for _, zone in ipairs(self.zones) do
      zone:draw()
    end
    for _, clipPoint in ipairs(self.clippingPoints) do
      clipPoint:draw()
    end
end

local function test()
end
test()

return TrackConfig
