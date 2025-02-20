local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('mode-runstate')

---@class RunState : ClassBase
---@field trackConfig TrackConfig
---@field driftState DriftState
---@field scoringObjectStates ScoringObjectState[]
---@field private finished boolean
local RunState = class("RunState")

function RunState:initialize(track_config)
    self.trackConfig = track_config
    self.scoringObjectStates = {}
    self.driftState = DriftState(0, 0, 0, 0)
    self.finished = false
    for idx, obj in ipairs(self.trackConfig.scoringObjects) do
        if obj.isInstanceOf(Zone) then
            self.scoringObjectStates[idx] = ZoneState(obj)
        elseif obj.isInstanceOf(Clip) then
            self.scoringObjectStates[idx] = ClipState(obj)
        else
            Assert.Error("")
        end
    end

    EventSystem.emit(EventSystem.Signal.ScoringObjectStatesReset, self.scoringObjectStates)
end

-- EXPERIMENTAL: Use ac.connect() for drift ratio multiplier sharing
local shared_data = ac.connect({
    ac.StructItem.key("driftmode__DriftState"),
    driftmode__drift_state_ratio = ac.StructItem.float()
})

---@param car_config CarConfig
---@param car ac.StateCar
function RunState:registerCar(car_config, car)
    self.driftState:calcDriftState(car, self.trackConfig.scoringRanges)

    self.driftState.ratio_mult = 0.0
    for _, scoring_object in ipairs(self.scoringObjectStates) do
        local res = scoring_object:registerCar(car_config, car, self.driftState)
        if res ~= nil then
            self.driftState.ratio_mult = res
            shared_data.driftmode__drift_state_ratio = res
            break
        end
    end
end

function RunState:getScore()
    local score = 0
    for _, scoring_object in ipairs(self.scoringObjectStates) do
        score = score + scoring_object:getScore()
    end
    return score
end

function RunState:getMaxScore()
    local score = 0
    for _, scoring_object in ipairs(self.scoringObjectStates) do
        score = score + scoring_object:getMaxScore()
    end
    return score
end

function RunState:getAvgMultiplier()
    local mult = 0
    local scoring_finished = 0
    for _, scoring_object_state in ipairs(self.scoringObjectStates) do
        if scoring_object_state:isDone() then
            mult = mult + scoring_object_state:getMultiplier()
            scoring_finished = scoring_finished + 1
        end
    end
    if scoring_finished == 0 then return 0 end
    mult = mult / scoring_finished
    return mult
end

function RunState:setFinished(value)
    self.finished = value
end

function RunState:getFinished()
    return self.finished
end

local function test()
end
test()

return RunState
