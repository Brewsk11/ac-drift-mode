local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')


---@class DriftState : ClassBase Lightweight class for passing information about drift state such as angle from a calculating module to UI
---@field speed_mult number
---@field angle_mult number
---@field ratio_mult number
---@field score_mult number
---@field side_drifting DriftState.Side
local DriftState = class("DriftState")
DriftState.__model_path = "DriftState"

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

---@param car ac.StateCar
---@param scoring_ranges ScoringRanges
function DriftState:calcDriftState(car, scoring_ranges)
    local car_direction = vec3(0, 0, 0)
    car.velocity:normalize(car_direction)

    self.speed_mult = scoring_ranges.speedRange:getFractionClamped(car.speedKmh)

    -- TODO: Somehow the dot sometimes is outside of the arccos domain, even though both v are normalized
    -- For now run additional check not to dirty the logs
    local car_angle = math.deg(math.acos(car_direction:dot(car.look)))
    if car_angle == car_angle then -- Check if nan
        self.angle_mult = scoring_ranges.angleRange:getFractionClamped(car_angle)
    end

    -- Ignore angle when min speed not reached, to avoid big fluctuations with low speed
    if self.speed_mult == 0 then
        self.angle_mult = 0
    end

    local dot = car.velocity:dot(car.side)
    if dot > 0 then
        self.side_drifting = DriftState.Side.LeftLeads
    else
        self.side_drifting = DriftState.Side.RightLeads
    end
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
