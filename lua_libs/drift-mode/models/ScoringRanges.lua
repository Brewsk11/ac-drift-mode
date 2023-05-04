local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringRanges
---@field speedRange Range
---@field angleRange Range
local ScoringRanges = {}
ScoringRanges.__index = ScoringRanges

function ScoringRanges.serialize(self)
    local data = {
        __class = "ScoringRanges",
        speedRange = S.serialize(self.speedRange),
        angleRange = S.serialize(self.angleRange)
    }

    return data
end

function ScoringRanges.deserialize(data)
    Assert.Equal(data.__class, "ScoringRanges", "Tried to deserialize wrong class")

    local obj = ScoringRanges.new()
    obj.speedRange = S.deserialize(data.speedRange)
    obj.angleRange = S.deserialize(data.angleRange)
    return obj
end

function ScoringRanges.new(speedRange, angleRange)
    local self = setmetatable({}, ScoringRanges)
    self.speedRange = speedRange
    self.angleRange = angleRange
    return self
end

local function test()
end
test()

return ScoringRanges
