local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunStateData : ClassBase Lightweight dataclass for brokering run information to apps
---@field scoringObjectStates ScoringObjectStateData[]
---@field driftState DriftState
---@field totalScore number
---@field maxScore number
---@field avgMultiplier number
local RunStateData = class("RunStateData")

function RunStateData:serialize()
    local data = {
        __class = "RunStateData",
        scoringObjectStates = S.serialize(self.scoringObjectStates),
        driftState = S.serialize(self.driftState),
        totalScore = S.serialize(self.totalScore),
        maxScore = S.serialize(self.maxScore),
        avgMultiplier = S.serialize(self.avgMultiplier),
    }

    return data
end

function RunStateData.deserialize(data)
    Assert.Equal(data.__class, "RunStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, RunStateData)
    obj.scoringObjectStates = S.deserialize(data.scoringObjectStates)
    obj.driftState = S.deserialize(data.driftState)
    obj.totalScore = S.deserialize(data.totalScore)
    obj.maxScore = S.deserialize(data.maxScore)
    obj.avgMultiplier = S.deserialize(data.avgMultiplier)
    return obj
end

local function test()
end
test()

return RunStateData
