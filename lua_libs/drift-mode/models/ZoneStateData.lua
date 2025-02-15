local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field active boolean
---@field performance number
---@field timeInZone number
---@field score_points ScoringObjectStateData[]
local ZoneStateData = class("ZoneStateData", ScoringObjectStateData)

function ZoneStateData:drawFlat(coord_transformer)
    for _, score in ipairs(self.score_points) do
        ui.drawCircleFilled(coord_transformer(score.point), 2, rgbm.colors.green
        )
    end
end

local function test()
end
test()

return ZoneStateData
