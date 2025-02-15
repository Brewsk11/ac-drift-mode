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

function ClipStateData:drawFlat(coord_transformer)
end

local function test()
end
test()

return ClipStateData
