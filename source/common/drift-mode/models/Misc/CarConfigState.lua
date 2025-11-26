local ModelBase = require("drift-mode.models.ModelBase")

---@class CarConfigState : ModelBase Lightweight class for passing information about the car configuration from a calculating module to UI
---@field shared_data { front_offset: number, front_span: number, rear_offset: number, rear_span: number }
local CarConfigState = class("CarConfigState", ModelBase)
CarConfigState.__model_path = "Misc.CarConfigState"

function CarConfigState:initialize()
    ModelBase.initialize(self)
    self.shared_data = ac.connect(self:createConnectLayout())
end

function CarConfigState:createConnectLayout()
    return {
        ac.StructItem.key("drift-mode.CarConfigState"),
        front_offset = ac.StructItem.float(),
        front_span = ac.StructItem.float(),
        rear_offset = ac.StructItem.float(),
        rear_span = ac.StructItem.float()
    }
end

function CarConfigState:drawAlignment()
    local state = ac.getCar(0)
    if state == nil then return end

    local front_center = state.position + state.look * self.shared_data.front_offset + state.up / 3
    local rear_center = state.position - state.look * self.shared_data.rear_offset + state.up / 3

    local front_align_right_center = front_center + state.side * self.shared_data.front_span
    local front_align_left_center = front_center - state.side * self.shared_data.front_span

    local rear_align_right_center = rear_center + state.side * self.shared_data.rear_span + state.look * 0.15
    local rear_align_left_center = rear_center - state.side * self.shared_data.rear_span + state.look * 0.15

    -- Draw rear alignment planes (and center, for now)
    render.debugPlane(rear_align_right_center, -state.look + state.side, rgbm(3, 0, 0, 1), 0.5)
    render.debugPlane(rear_align_left_center, -state.look - state.side, rgbm(3, 0, 0, 1), 0.5)

    -- Draw front alignment points
    render.debugSphere(front_align_right_center, 0.025)
    render.debugSphere(front_align_left_center, 0.025)
    render.debugPlane(front_align_right_center, state.look + state.side, rgbm(0, 0, 3, 1), 0.5)
    render.debugPlane(front_align_left_center, state.look - state.side, rgbm(0, 0, 3, 1), 0.5)
end

local function test()
end
test()

return CarConfigState
