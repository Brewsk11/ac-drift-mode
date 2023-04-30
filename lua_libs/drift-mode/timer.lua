local Assert = require('drift-mode/assert')

---@class Timer
---@field period number
---@field private timer number
---@field task function
local Timer = {}
Timer.__index = Timer

function Timer.new(period, task)
    local self = setmetatable({}, Timer)
    self.period = period
    self.timer = 0
    self.task = task
    return self
end

function Timer:tick(dt)
    self.timer = self.timer + dt
    if self.timer > self.period then
        self.task()
        self.timer = self.timer - self.period
        return true
    end
    return false
end

local function test()
end
test()

return Timer
