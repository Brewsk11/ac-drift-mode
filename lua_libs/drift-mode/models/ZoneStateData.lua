local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field active boolean
---@field performance number
---@field timeInZone number
local ZoneStateData = class("ZoneStateData", ScoringObjectStateData)

function ZoneStateData:serialize()
    local data = {
        __class = "ZoneStateData",
        name = S.serialize(self.name),
        done = S.serialize(self.done),
        score = S.serialize(self.score),
        max_score = S.serialize(self.max_score),
        speed = S.serialize(self.speed),
        angle = S.serialize(self.angle),
        depth = S.serialize(self.depth),

        active = S.serialize(self.active),
        performance = S.serialize(self.performance),
        timeInZone = S.serialize(self.timeInZone),
    }

    return data
end

function ZoneStateData.deserialize(data)
    Assert.Equal(data.__class, "ZoneStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, ZoneStateData)
    obj.name = S.deserialize(data.name)
    obj.done = S.deserialize(data.done)
    obj.score = S.deserialize(data.score)
    obj.max_score = S.deserialize(data.max_score)
    obj.speed = S.deserialize(data.speed)
    obj.angle = S.deserialize(data.angle)
    obj.depth = S.deserialize(data.depth)

    obj.active = S.deserialize(data.active)
    obj.performance = S.deserialize(data.performance)
    obj.timeInZone = S.deserialize(data.timeInZone)
    return obj
end

local function test()
end
test()

return ZoneStateData
