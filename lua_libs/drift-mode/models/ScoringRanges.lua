---@class ScoringRanges : ClassBase
---@field speedRange Range
---@field angleRange Range
local ScoringRanges = class("ScoringRanges")
ScoringRanges.__model_path = "ScoringRanges"

function ScoringRanges:initialize(speedRange, angleRange)
    -- TODO: Move defaults here from TrackConfig init
    self.speedRange = speedRange
    self.angleRange = angleRange
end

local function test()
end
test()

return ScoringRanges
