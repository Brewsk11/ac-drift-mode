local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

local EventSystem = require('drift-mode.eventsystem')
local DriftState = require("drift-mode.models.Misc.DriftState")
local Zone = require("drift-mode.models.Elements.Scorables.Zone.Zone")
local ZoneState = require("drift-mode.models.Elements.Scorables.Zone.ZoneState")
local Clip = require("drift-mode.models.Elements.Scorables.Clip.Clip")
local ClipState = require("drift-mode.models.Elements.Scorables.Clip.ClipState")
local ZoneArc = require("drift-mode.models.Elements.Scorables.ZoneArc.ZoneArc")
local ZoneArcState = require("drift-mode.models.Elements.Scorables.ZoneArc.ZoneArcState")


---@class RunState : ClassBase
---@field trackConfig TrackConfig
---@field driftState DriftState
---@field scoringObjectStates ScorableState[]
---@field private finished boolean
local RunState = class("RunState", ModelBase)
RunState.__model_path = "Elements.Course.RunState"

function RunState:initialize(track_config)
    self.trackConfig = track_config
    self.scoringObjectStates = {}
    self.driftState = DriftState(0, 0, 0, 0)
    self.finished = false
    for idx, obj in ipairs(self.trackConfig.scorables) do
        if Zone.isInstanceOf(obj) then
            self.scoringObjectStates[idx] = ZoneState(obj)
        elseif Clip.isInstanceOf(obj) then
            self.scoringObjectStates[idx] = ClipState(obj)
        elseif ZoneArc.isInstanceOf(obj) then
            self.scoringObjectStates[idx] = ZoneArcState(obj)
        else
            Assert.Error("")
        end
    end

    EventSystem:emit(EventSystem.Signal.ScorableStatesReset, self.scoringObjectStates)
end

function RunState:calcDriftState(car)
    self.driftState:calcDriftState(car, self.trackConfig.scoringRanges)
end

---@param car_config CarConfig
---@param car ac.StateCar
function RunState:registerCar(car_config, car)
    self.driftState:calcDriftState(car, self.trackConfig.scoringRanges)

    self.driftState.shared_data.ratio_mult = 0.0
    for _, scoring_object in ipairs(self.scoringObjectStates) do
        local res = scoring_object:registerCar(car_config, car, self.driftState)
        if res ~= nil then
            self.driftState.shared_data.ratio_mult = res
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
