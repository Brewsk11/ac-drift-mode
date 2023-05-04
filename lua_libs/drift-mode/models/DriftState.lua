local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DriftState Lightweight class for passing information about drift state such as angle from a calculating module to UI
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
local DriftState = {}
DriftState.__index = DriftState

function DriftState.new(speed_mult, angle_mult, ratio_mult)
    local self = setmetatable({}, DriftState)
    self.speed_mult = speed_mult
    self.angle_mult = angle_mult
    self.ratio_mult = ratio_mult
    return self
end

function DriftState.serialize(self)
    local data = {
        __class = "DriftState",
        speed_mult = S.serialize(self.speed_mult),
        angle_mult = S.serialize(self.angle_mult),
        ratio_mult = S.serialize(self.ratio_mult),
    }

    return data
end

function DriftState.deserialize(data)
    Assert.Equal(data.__class, "DriftState", "Tried to deserialize wrong class")
    local obj = setmetatable({}, DriftState)
    obj.speed_mult = S.deserialize(data.speed_mult)
    obj.angle_mult = S.deserialize(data.angle_mult)
    obj.ratio_mult = S.deserialize(data.ratio_mult)
    return obj
end

function DriftState:getFinalMult()
    if not self.speed_mult or not self.angle_mult or not self.ratio_mult then return 0.0 end
    return self.speed_mult * self.angle_mult * self.ratio_mult
end

local function test()
end
test()

return DriftState
