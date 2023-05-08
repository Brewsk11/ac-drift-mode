local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@enum TrackConfigType
TrackConfigType = {
    User = "User",
    Official = "Official"
}

---@class TrackConfigInfo
---@field name string
---@field path string
---@field type TrackConfigType
local TrackConfigInfo = {}
TrackConfigInfo.__index = TrackConfigInfo

function TrackConfigInfo.serialize(self)
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
    local obj = TrackConfigInfo.new()
    obj.name = S.deserialize(data.name)
    obj.path = S.deserialize(data.path)
    obj.type = S.deserialize(data.type)
    return obj
end

function TrackConfigInfo.new(name, path, type)
    local self = setmetatable({}, TrackConfigInfo)
    self.name = name
    self.path = path
    self.type = type
    return self
end

local function test()
end
test()

return TrackConfigInfo
