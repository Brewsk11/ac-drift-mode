local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field maxPoints integer
---@field score number
---@field performance number
---@field multiplier number
---@field hitPoint Point
---@field hitRatioMult number
local ClipStateData = class("ClipStateData", ScoringObjectStateData)

function ClipStateData:initialize()
end

function ClipStateData:serialize()
    local data = {
        __class = "ClipStateData",
        name = S.serialize(self.name),
        done = S.serialize(self.done),
        score = S.serialize(self.score),
        max_score = S.serialize(self.max_score),
        speed = S.serialize(self.speed),
        angle = S.serialize(self.angle),
        depth = S.serialize(self.depth),

        performance = S.serialize(self.performance),
        multiplier = S.serialize(self.multiplier),
        hitPoint = S.serialize(self.hitPoint),
        hitRatioMult = S.serialize(self.hitRatioMult),
    }

    return data
end

function ClipStateData.deserialize(data)
    Assert.Equal(data.__class, "ClipStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, ClipStateData)
    obj.name = S.deserialize(data.name)
    obj.done = S.deserialize(data.done)
    obj.score = S.deserialize(data.score)
    obj.max_score = S.deserialize(data.max_score)
    obj.speed = S.deserialize(data.speed)
    obj.angle = S.deserialize(data.angle)
    obj.depth = S.deserialize(data.depth)

    obj.performance = S.deserialize(data.performance)
    obj.multiplier = S.deserialize(data.multiplier)
    obj.hitPoint = S.deserialize(data.hitPoint)
    obj.hitRatioMult = S.deserialize(data.hitRatioMult)
    return obj
end

local function test()
end
test()

return ClipStateData
