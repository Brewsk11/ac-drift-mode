local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringObjectStateData : ClassBase
---@field name string
---@field done boolean
---@field score number
---@field max_score number
---@field speed number
---@field angle number
---@field depth number
local ScoringObjectStateData = class("ScoringObjectStateData")

function ScoringObjectStateData:initialize()
end

function ScoringObjectStateData:drawFlat(coord_transformer)
end

local function test()
end
test()

return ScoringObjectStateData
