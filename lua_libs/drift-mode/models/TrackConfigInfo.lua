local Assert = require('drift-mode/assert')
local ConfigIO = require('drift-mode/configio')

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
TrackConfigInfo.__model_path = "TrackConfigInfo"

function TrackConfigInfo:initialize(name, path, type)
    self.name = name
    self.path = path
    self.type = type
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
