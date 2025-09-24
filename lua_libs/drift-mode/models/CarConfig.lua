-- Car configuration

---@class CarConfig : ClassBase Data class describing key car points positions for scoring purposes
---@field frontOffset number Offset from car origin to the front bumper
---@field frontSpan number Span between two endpoints of the front bumper
---@field rearOffset number Offset from car origin to the rear bumper
---@field rearSpan number Span between two endpoints of the rear bumper
local CarConfig = class("CarConfig")
CarConfig.__model_path = "CarConfig"

function CarConfig:initialize(frontOffset, frontSpan, rearOffset, rearSpan)
    self.frontOffset = frontOffset or 2.3
    self.frontSpan = frontSpan or 1
    self.rearOffset = rearOffset or 2.4
    self.rearSpan = rearSpan or 1
end

function CarConfig:drawAlignment()
    local state = ac.getCar(0)

    local rear_center = state.position - state.look * self.rearOffset + state.up / 3
    local front_center = state.position + state.look * self.frontOffset + state.up / 3

    local rear_align_right_center = rear_center + state.side * self.rearSpan + state.look * 0.15
    local rear_align_left_center = rear_center - state.side * self.rearSpan + state.look * 0.15

    local front_align_right_center = front_center + state.side * self.frontSpan
    local front_align_left_center = front_center - state.side * self.frontSpan

    -- Draw rear alignment planes (and center, for now)
    render.debugPlane(rear_align_right_center, -state.look + state.side, rgb(3, 0, 0), 0.5)
    render.debugPlane(rear_align_left_center, -state.look - state.side, rgb(3, 0, 0), 0.5)

    -- Draw front alignment points
    render.debugSphere(front_align_right_center, 0.025)
    render.debugSphere(front_align_left_center, 0.025)
    render.debugPlane(front_align_right_center, state.look + state.side, rgb(0, 0, 3), 0.5)
    render.debugPlane(front_align_left_center, state.look - state.side, rgb(0, 0, 3), 0.5)
end

local function test()
end
test()

return CarConfig
