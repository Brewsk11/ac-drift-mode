local ModelBase = require("drift-mode.models.ModelBase")

---@class DriftState : ModelBase Lightweight class for passing information about drift state such as angle from a calculating module to UI
---@field shared_data { speed_mult: number, angle_mult: number, ratio_mult: number, side_drifting: DriftState.Side }
---@field side_drifting DriftState.Side
local DriftState = class("DriftState", ModelBase)
DriftState.__model_path = "Misc.DriftState"

---@enum DriftState.Side
DriftState.Side = {
    LeftLeads = 1,
    RightLeads = -1
}

function DriftState:initialize()
    ModelBase.initialize(self)

    self.shared_data = ac.connect(self:createConnectLayout())
end

function DriftState:createConnectLayout()
    return {
        ac.StructItem.key("drift-mode.DriftState"),
        speed_mult = ac.StructItem.double(),
        angle_mult = ac.StructItem.double(),
        ratio_mult = ac.StructItem.double(),
        side_drifting = ac.StructItem.int8()
    }
end

function DriftState:getFinalMult()
    if not self.shared_data.speed_mult or not self.shared_data.angle_mult or not self.shared_data.ratio_mult then return 0.0 end
    return self.shared_data.speed_mult * self.shared_data.angle_mult * self.shared_data.ratio_mult
end

---@param car ac.StateCar
---@param scoring_ranges ScoringRanges
function DriftState:calcDriftState(car, scoring_ranges)
    local car_direction = vec3(0, 0, 0)
    car.velocity:normalize(car_direction)

    self.shared_data.speed_mult = scoring_ranges.speedRange:getFractionClamped(car.speedKmh)

    -- TODO: Somehow the dot sometimes is outside of the arccos domain, even though both v are normalized
    -- For now run additional check not to dirty the logs
    local car_angle = math.deg(math.acos(car_direction:dot(car.look)))
    if car_angle == car_angle then -- Check if nan
        self.shared_data.angle_mult = scoring_ranges.angleRange:getFractionClamped(car_angle)
    end

    -- Ignore angle when min speed not reached, to avoid big fluctuations with low speed
    if self.shared_data.speed_mult == 0 then
        self.shared_data.angle_mult = 0
    end

    local dot = car.velocity:dot(car.side)
    if dot > 0 then
        self.shared_data.side_drifting = DriftState.Side.LeftLeads
    else
        self.shared_data.side_drifting = DriftState.Side.RightLeads
    end
end

function DriftState:drawDebug()
    local car = ac.getCar(0)
    render.debugArrow(car.position, car.position + car.velocity, 0.1)
    render.debugArrow(car.position, car.position + car.look, 0.1)

    render.debugArrow(car.position, car.position + car.side * self.shared_data.side_drifting, 0.1)
end

local function test()
end
test()

return DriftState
