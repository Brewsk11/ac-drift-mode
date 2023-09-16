local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field active boolean
---@field performance number
---@field timeInZone number
local ZoneStateData = class("ZoneStateData", ScoringObjectStateData)

local function test()
end
test()

return ZoneStateData
