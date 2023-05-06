local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunStateData Lightweight dataclass for brokering run information to apps
---@field zoneStates ZoneStateData[]
---@field clipStates ClipStateData[]
---@field driftState DriftState
---@field totalScore number
---@field avgMultiplier number
local RunStateData = {}
RunStateData.__index = RunStateData

function RunStateData.serialize(self)
    local data = {
        __class = "RunStateData",
        zoneStates = S.serialize(self.zoneStates),
        clipStates = S.serialize(self.clipStates),
        driftState = S.serialize(self.driftState),
        totalScore = S.serialize(self.totalScore),
        avgMultiplier = S.serialize(self.avgMultiplier),
    }

    return data
end

function RunStateData.deserialize(data)
    Assert.Equal(data.__class, "RunStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, RunStateData)
    obj.zoneStates = S.deserialize(data.zoneStates)
    obj.clipStates = S.deserialize(data.clipStates)
    obj.driftState = S.deserialize(data.driftState)
    obj.totalScore = S.deserialize(data.totalScore)
    obj.avgMultiplier = S.deserialize(data.avgMultiplier)
    return obj
end

local function test()
end
test()

return RunStateData
