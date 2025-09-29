local ModelBase = require("drift-mode.models.ModelBase")
---@enum TrackConfigType
TrackConfigType = {
    User = "User",
    Official = "Official"
}

---@class TrackConfigInfo : ClassBase
---@field name string
---@field path string
---@field type TrackConfigType
local TrackConfigInfo = class("TrackConfigInfo", ModelBase)
TrackConfigInfo.__model_path = "TrackConfigInfo"

function TrackConfigInfo:initialize(name, path, type)
    self.name = name
    self.path = path
    self.type = type
end

local function test()
end
test()

return TrackConfigInfo
