local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipStateData Lightweight dataclass for brokering run information to apps
---@field clip string
---@field maxPoints integer
---@field crossed boolean
---@field score number
---@field performance number
---@field multiplier number
---@field hitPoint Point
---@field hitRatioMult number
local ClipStateData = {}
ClipStateData.__index = ClipStateData

function ClipStateData.serialize(self)
    local data = {
        __class = "ClipStateData",
        clip = S.serialize(self.clip),
        maxPoints = S.serialize(self.maxPoints),
        crossed = S.serialize(self.crossed),
        score = S.serialize(self.score),
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
    obj.clip = S.deserialize(data.clip)
    obj.maxPoints = S.deserialize(data.maxPoints)
    obj.crossed = S.deserialize(data.crossed)
    obj.score = S.deserialize(data.score)
    obj.performance = S.deserialize(data.performance)
    obj.hitPoint = S.deserialize(data.hitPoint)
    obj.hitRatioMult = S.deserialize(data.hitRatioMult)
    return obj
end

local function test()
end
test()

return ClipStateData
