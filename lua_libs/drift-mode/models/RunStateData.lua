local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunStateData : ClassBase Lightweight dataclass for brokering run information to apps
---@field scoringObjectStates ScoringObjectStateData[]
---@field driftState DriftState
---@field totalScore number
---@field maxScore number
---@field avgMultiplier number
local RunStateData = class("RunStateData")

local function test()
end
test()

return RunStateData
