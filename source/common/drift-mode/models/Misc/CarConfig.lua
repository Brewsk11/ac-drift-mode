local ModelBase = require("drift-mode.models.ModelBase")
-- Car configuration

---@class CarConfig : ClassBase Data class describing key car points positions for scoring purposes
---@field frontOffset number Offset from car origin to the front bumper
---@field frontSpan number Span between two endpoints of the front bumper
---@field rearOffset number Offset from car origin to the rear bumper
---@field rearSpan number Span between two endpoints of the rear bumper
local CarConfig = class("CarConfig", ModelBase)
CarConfig.__model_path = "Misc.CarConfig"

function CarConfig:initialize(frontOffset, frontSpan, rearOffset, rearSpan)
    self.frontOffset = frontOffset or 2.3
    self.frontSpan = frontSpan or 1
    self.rearOffset = rearOffset or 2.4
    self.rearSpan = rearSpan or 1
end

local function test()
end
test()

return CarConfig
