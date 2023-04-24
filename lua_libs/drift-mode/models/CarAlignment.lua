-- Car setup models

---@class CarAlignment Data class describing key car points positions for scoring purposes
---@field frontOffset number Offset from car origin to the front bumper
---@field frontSpan number Span between two endpoints of the front bumper
---@field rearOffset number Offset from car origin to the rear bumper
---@field rearSpan number Span between two endpoints of the rear bumper
local CarAlignment = {}

local Assert = require('drift-mode/assert')
local function test()
end
test()

return CarAlignment