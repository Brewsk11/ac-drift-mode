local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

-- Car configuration

---@class CarConfig Data class describing key car points positions for scoring purposes
---@field frontOffset number Offset from car origin to the front bumper
---@field frontSpan number Span between two endpoints of the front bumper
---@field rearOffset number Offset from car origin to the rear bumper
---@field rearSpan number Span between two endpoints of the rear bumper
local CarConfig = {}
CarConfig.__index = CarConfig



function CarConfig.serialize(self)
    local data = {
        __class = "CarConfig",
        frontOffset = S.serialize(self.frontOffset),
        frontSpan = S.serialize(self.frontSpan),
        rearOffset = S.serialize(self.rearOffset),
        rearSpan = S.serialize(self.rearSpan)
    }

    return data
end

function CarConfig.deserialize(data)
    Assert.Equal(data.__class, "CarConfig", "Tried to deserialize wrong class")

    local obj = CarConfig.new()

    obj.frontOffset = S.deserialize(data.frontOffset)
    obj.frontSpan = S.deserialize(data.frontSpan)
    obj.rearOffset = S.deserialize(data.rearOffset)
    obj.rearSpan = S.deserialize(data.rearSpan)
    return obj
end

function CarConfig.new(frontOffset, frontSpan, rearOffset, rearSpan)
    local self = setmetatable({}, CarConfig)
    self.frontOffset = frontOffset or 2.3
    self.frontSpan = frontSpan or 1
    self.rearOffset = rearOffset or 2.4
    self.rearSpan = rearSpan or 1
    return self
end

function CarConfig.drawAlignment(self)
    local state = ac.getCar(0)

    local rear_center = state.position - state.look * self.rearOffset + state.up / 3
    local front_center = state.position + state.look * self.frontOffset + state.up / 3

    local rear_align_right_center = rear_center + state.side * self.rearSpan + state.look * 0.15
    local rear_align_left_center =  rear_center - state.side * self.rearSpan + state.look * 0.15

    local front_align_right_center = front_center + state.side * self.frontSpan
    local front_align_left_center =  front_center - state.side * self.frontSpan

    -- Draw rear alignment planes (and center, for now)
    for i = -2, 2, 1 do
      render.debugPlane(rear_center + state.side * i * 0.6, -state.look, rgb(3, 0, 0), 0.6)
    end
    render.debugPlane(rear_align_right_center, state.side, rgb(0, 3, 0), 0.6)
    render.debugPlane(rear_align_left_center, -state.side, rgb(0, 3, 0), 0.6)

    render.debugPoint(rear_center, 1)

    -- Draw front alignment points
    render.debugSphere(front_align_right_center, 0.025)
    render.debugSphere(front_align_left_center, 0.025)
end

local function test()
end
test()

return CarConfig
