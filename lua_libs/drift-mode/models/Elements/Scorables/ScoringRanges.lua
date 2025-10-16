local ModelBase = require("drift-mode.models.ModelBase")
---@class ScoringRanges : ClassBase
---@field speedRange Range
---@field angleRange Range
local ScoringRanges = class("ScoringRanges", ModelBase)
ScoringRanges.__model_path = "Elements.Scorables.ScoringRanges"

function ScoringRanges:initialize(speedRange, angleRange)
    ModelBase:initialize()
    -- TODO: Move defaults here from TrackConfig init
    self.speedRange = speedRange
    self.angleRange = angleRange
end

local function test()
end
test()

return ScoringRanges
