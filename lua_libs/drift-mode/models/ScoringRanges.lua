local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringRanges : ClassBase
---@field speedRange Range
---@field angleRange Range
local ScoringRanges = class("ScoringRanges")

function ScoringRanges:initialize(speedRange, angleRange)
    -- TODO: Move defaults here from TrackConfig init
    self.speedRange = speedRange
    self.angleRange = angleRange
end

function ScoringRanges:serialize()
    local data = {
        __class = "ScoringRanges",
        speedRange = S.serialize(self.speedRange),
        angleRange = S.serialize(self.angleRange)
    }

    return data
end

function ScoringRanges.deserialize(data)
    Assert.Equal(data.__class, "ScoringRanges", "Tried to deserialize wrong class")

    local obj = ScoringRanges()
    obj.speedRange = S.deserialize(data.speedRange)
    obj.angleRange = S.deserialize(data.angleRange)
    return obj
end

local function test()
end
test()

return ScoringRanges
