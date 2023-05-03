local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneStateData Lightweight dataclass for brokering run information to apps
---@field zone string
---@field maxPoints integer
---@field active boolean
---@field finished boolean
---@field score number
---@field performance number
---@field timeInZone number
local ZoneStateData = {}
ZoneStateData.__index = ZoneStateData

function ZoneStateData.serialize(self)
    local data = {
        __class = "ZoneStateData",
        zone = S.serialize(self.zone),
        maxPoints = S.serialize(self.maxPoints),
        active = S.serialize(self.active),
        finished = S.serialize(self.finished),
        score = S.serialize(self.score),
        performance = S.serialize(self.performance),
        timeInZone = S.serialize(self.timeInZone),
    }

    return data
end

function ZoneStateData.deserialize(data)
    Assert.Equal(data.__class, "ZoneStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, ZoneStateData)
    obj.zone = S.deserialize(data.zone)
    obj.maxPoints = S.deserialize(data.maxPoints)
    obj.active = S.deserialize(data.active)
    obj.finished = S.deserialize(data.finished)
    obj.score = S.deserialize(data.score)
    obj.performance = S.deserialize(data.performance)
    obj.timeInZone = S.deserialize(data.timeInZone)
    return obj
end

local function test()
end
test()

return ZoneStateData
