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
---@field multiplier number
local ScoringObjectStateData = class("ScoringObjectStateData")

function ScoringObjectStateData:initialize()
end

---Draw the object state in a UI element
---@param coord_transformer fun(Point): vec2 Use this for world space points to map to UI minimap space
function ScoringObjectStateData:drawFlat(coord_transformer)
    Assert.Error("Called abstract method!")
end

local function test()
end
test()

return ScoringObjectStateData
