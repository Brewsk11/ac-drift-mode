local Assert = require('drift-mode/assert')
local ConfigIO = require('drift-mode/configio')

local S = require('drift-mode/serializer')

---@enum TrackConfigType
TrackConfigType = {
    User = "User",
    Official = "Official"
}

---@class TrackConfigInfo : ClassBase
---@field name string
---@field path string
---@field type TrackConfigType
local TrackConfigInfo = class("TrackConfigInfo")

function TrackConfigInfo:initialize(name, path, type)
    self.name = name
    self.path = path
    self.type = type
end

function TrackConfigInfo:serialize()
    local data = {
        __class = "TrackConfigInfo",
        name = S.serialize(self.name),
        path = S.serialize(self.path),
        type = S.serialize(self.type),
    }
    return data
end

function TrackConfigInfo.deserialize(data)
    Assert.Equal(data.__class, "TrackConfigInfo", "Tried to deserialize wrong class")
    local obj = TrackConfigInfo()
    obj.name = S.deserialize(data.name)
    obj.path = S.deserialize(data.path)
    obj.type = S.deserialize(data.type)
    return obj
end

---@return TrackConfig?
function TrackConfigInfo:load()
    Assert.NotNil(self.path, "Tried to load track from empty TrackConfigInfo")
    return ConfigIO.loadTrackConfig(self)
end

local function test()
end
test()

return TrackConfigInfo
