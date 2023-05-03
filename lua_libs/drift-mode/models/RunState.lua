local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunState
---@field trackConfig TrackConfig
---@field zoneStates ZoneState[]
local RunState = {}
RunState.__index = RunState

---Serializes to lightweight RunStateData as RunState should not be brokered.
---@param self RunState
---@return table
function RunState.serialize(self)
    local data = {
        __class = "RunStateData",
        zoneStates = S.serialize(self.zoneStates),
        totalScore = S.serialize(self:getScore()),
        totalPerformance = S.serialize(self:getPerformance()),
    }

    return data
end

function RunState.new(track_config)
    local self = setmetatable({}, RunState)
    self.trackConfig = track_config
    self.zoneStates = {}
    for _, zone in ipairs(self.trackConfig.zones) do
        self.zoneStates[#self.zoneStates+1] = ZoneState.new(zone)
    end
    return self
end

function RunState:registerPosition(point, speed_mult, angle_mult)
    local ratio = nil
    for _, zone in ipairs(self.zoneStates) do
        local res = zone:registerPosition(point, speed_mult, angle_mult)
        if res ~= nil then ratio = res end
    end
    return ratio
end

function RunState:getScore()
    local score = 0
    for _, zone_state in ipairs(self.zoneStates) do
        score = score + zone_state:getScore()
    end
    return score
end

function RunState:getPerformance()
    local mult = 0
    local zones_finished = 0
    for _, zone_state in ipairs(self.zoneStates) do
        if zone_state:isFinished() then
            mult = mult + zone_state:getMultiplier()
            zones_finished = zones_finished + 1
        end
    end
    if zones_finished == 0 then return 0 end
    mult = mult / zones_finished
    return mult
end

function RunState:draw()
    for _, zone_state in ipairs(self.zoneStates) do
        zone_state:draw()
    end

    if self.trackConfig.startLine then self.trackConfig.startLine:draw(rgbm(0, 3, 0, 1)) end
    if self.trackConfig.finishLine then self.trackConfig.finishLine:draw(rgbm(0, 0, 3, 1)) end
end

local function test()
end
test()

return RunState
