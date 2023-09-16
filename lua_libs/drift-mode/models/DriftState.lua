local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')


---@class DriftState : ClassBase Lightweight class for passing information about drift state such as angle from a calculating module to UI
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
---@field side_drifting DriftState.Side
local DriftState = class("DriftState")

---@enum DriftState.Side
DriftState.Side = {
    LeftLeads = 1,
    RightLeads = -1
}

function DriftState:initialize(speed_mult, angle_mult, ratio_mult, side_drifting)
    self.speed_mult = speed_mult
    self.angle_mult = angle_mult
    self.ratio_mult = ratio_mult
    self.side_drifting = side_drifting
end

function DriftState:getFinalMult()
    if not self.speed_mult or not self.angle_mult or not self.ratio_mult then return 0.0 end
    return self.speed_mult * self.angle_mult * self.ratio_mult
end

function DriftState:drawDebug()
    local car = ac.getCar(0)
    render.debugArrow(car.position, car.position + car.velocity, 0.1)
    render.debugArrow(car.position, car.position + car.look, 0.1)

    render.debugArrow(car.position, car.position + car.side * self.side_drifting, 0.1)
end

local function test()
end
test()

return DriftState
