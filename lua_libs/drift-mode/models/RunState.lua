local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class RunState
---@field trackConfig TrackConfig
---@field driftState DriftState
---@field zoneStates ZoneState[]
---@field clipStates ClipState[]
local RunState = {}
RunState.__index = RunState

---Serializes to lightweight RunStateData as RunState should not be brokered.
---@param self RunState
---@return table
function RunState.serialize(self)
    local data = {
        __class = "RunStateData",
        zoneStates = S.serialize(self.zoneStates),
        clipStates = S.serialize(self.clipStates),
        driftState = S.serialize(self.driftState),
        totalScore = S.serialize(self:getScore()),
        totalPerformance = S.serialize(self:getPerformance()),
    }

    return data
end

function RunState.new(track_config)
    local self = setmetatable({}, RunState)
    self.trackConfig = track_config
    self.zoneStates = {}
    self.clipStates = {}
    self.driftState = DriftState.new(0, 0, 0, 0)
    for _, zone in ipairs(self.trackConfig.zones) do
        self.zoneStates[#self.zoneStates+1] = ZoneState.new(zone)
    end
    for _, clip in ipairs(self.trackConfig.clips) do
        self.clipStates[#self.clipStates+1] = ClipState.new(clip)
    end
    return self
end

function RunState:registerPosition(point, speed_mult, angle_mult)
    local ratio = nil
    for _, zone in ipairs(self.zoneStates) do
        local res = zone:registerPosition(point, speed_mult, angle_mult)
        if res ~= nil then ratio = res end
    end
    for _, clip in ipairs(self.clipStates) do
        clip:registerPosition(point, speed_mult, angle_mult)
    end
    return ratio
end

function RunState:getScore()
    local score = 0
    for _, zone_state in ipairs(self.zoneStates) do
        score = score + zone_state:getScore()
    end
    for _, clip_state in ipairs(self.clipStates) do
        score = score + clip_state:getScore()
    end
    return score
end

function RunState:getPerformance()
    local mult = 0
    local scoring_finished = 0
    for _, zone_state in ipairs(self.zoneStates) do
        if zone_state:isFinished() then
            mult = mult + zone_state:getMultiplier()
            scoring_finished = scoring_finished + 1
        end
    end
    for _, clip_state in ipairs(self.clipStates) do
        if clip_state.crossed then
            mult = mult + clip_state:getMultiplier()
            scoring_finished = scoring_finished + 1
        end
    end
    if scoring_finished == 0 then return 0 end
    mult = mult / scoring_finished
    return mult
end

function RunState:draw()
    for _, zone_state in ipairs(self.zoneStates) do
        zone_state:draw()
    end

    if self.trackConfig.startLine then self.trackConfig.startLine:draw(rgbm(0, 3, 0, 1)) end
    if self.trackConfig.finishLine then self.trackConfig.finishLine:draw(rgbm(0, 0, 3, 1)) end
end

function RunState:drawDebug()
    self.driftState:drawDebug()
end

local function test()
end
test()

return RunState
