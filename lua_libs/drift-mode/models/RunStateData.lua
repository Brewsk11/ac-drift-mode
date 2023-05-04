local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunStateData Lightweight dataclass for brokering run information to apps
---@field zoneStates ZoneStateData[]
---@field clipStates ClipStateData[]
---@field totalScore number
---@field totalPerformance number
local RunStateData = {}
RunStateData.__index = RunStateData

function RunStateData.serialize(self)
    local data = {
        __class = "RunStateData",
        zoneStates = S.serialize(self.zoneStates),
        clipStates = S.serialize(self.clipStates),
        totalScore = S.serialize(self.totalScore),
        totalPerformance = S.serialize(self.totalPerformance),
    }

    return data
end

function RunStateData.deserialize(data)
    Assert.Equal(data.__class, "RunStateData", "Tried to deserialize wrong class")
    local obj = setmetatable({}, RunStateData)
    obj.zoneStates = S.deserialize(data.zoneStates)
    obj.clipStates = S.deserialize(data.clipStates)
    obj.totalScore = S.deserialize(data.totalScore)
    obj.totalPerformance = S.deserialize(data.totalPerformance)
    return obj
end

local function test()
end
test()

return RunStateData
