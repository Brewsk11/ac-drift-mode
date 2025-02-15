local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ZoneStateData : ScoringObjectStateData Lightweight dataclass for brokering run information to apps
---@field active boolean
---@field performance number
---@field timeInZone number
---@field score_points ZoneScoringPoint[]
local ZoneStateData = class("ZoneStateData", ScoringObjectStateData)

function ZoneStateData:drawFlat(coord_transformer)
    for _, score in ipairs(self.score_points) do
        local color = rgbm.colors.white - rgbm.colors.fuchsia * score.angle_mult
        color.mult = 1
        ui.drawCircleFilled(
            coord_transformer(score.point),
            4 - score.speed_mult * 2,
            color)
    end
end

local function test()
end
test()

return ZoneStateData
