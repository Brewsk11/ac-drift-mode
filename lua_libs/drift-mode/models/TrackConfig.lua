local Assert = require('drift-mode/assert')
local Zone = require('drift-mode/models/Zone')

-- Track configration data

---@class TrackConfig Data class describing key car points positions for scoring purposes
---@field zones Zone[] Offset from car origin to the front bumper
local TrackConfig = {}
TrackConfig.__index = TrackConfig

function TrackConfig.serialize(self)
    local data = {
        __class = "TrackConfig",
        zones = {}
    }

    for idx, zone in ipairs(self.zones) do
        data.zones[idx] = zone:serialize()
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

    obj.zones = zones
    return obj
end

function TrackConfig.new(zones)
    local self = setmetatable({}, TrackConfig)
    local _zones = zones or {}
    self.zones = _zones
    return self
end

local function test()
end
test()

return TrackConfig
