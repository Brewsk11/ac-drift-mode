local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ClipStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field maxPoints integer
---@field score number
---@field performance number
---@field hitPoint Point
---@field hitRatioMult number
local ClipStateData = class("ClipStateData", ScoringObjectStateData)

function ClipStateData:initialize()
end

---@param coord_transformer fun(point: Point): vec2
function ClipStateData:drawFlat(coord_transformer)
    if self.hitPoint == nil then return end
    ui.drawCircle(coord_transformer(self.hitPoint), 5 - self.performance * 5, rgbm.colors.lime)
end

local function test()
end
test()

return ClipStateData
