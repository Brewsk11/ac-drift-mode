local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@class ScoringObjectState : ClassBase
local ScoringObjectState = class("ScoringObjectState", ModelBase)
ScoringObjectState.__model_path = "Elements.Scorables.ScoringObjectState"

function ScoringObjectState:initialize()
end

function ScoringObjectState:getScore()
    Assert.Error("Abstract method called")
end

function ScoringObjectState:getMaxScore()
    Assert.Error("Abstract method called")
end

function ScoringObjectState:consumeUpdate(payload)
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:updatesFully()
    Assert.Error("Called abstract method!")
end

---@return string
function ScoringObjectState:getName()
    Assert.Error("Called abstract method!")
    return ""
end

function ScoringObjectState:getId()
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:isDone()
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:getSpeed()
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:getAngle()
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:getDepth()
    Assert.Error("Called abstract method!")
end

function ScoringObjectState:getMultiplier()
    Assert.Error("Called abstract method!")
end

---Register position of the car and update the score if the object was scored.
---@param car_config CarConfig
---@param car ac.StateCar
---@param drift_state DriftState
---@return number|nil [0, 1] Depth/ratio of the object scored or nil if registered outside of the object
function ScoringObjectState:registerCar(car_config, car, drift_state)
    Assert.Error("Abstract method called")
end

---Draw itself using ui.* calls
---@param coord_transformer fun(point: Point): vec2 Function converting true coordinate to canvas coordinate
---@param scale number
function ScoringObjectState:drawFlat(coord_transformer, scale)
    Assert.Error("Called abstract method!")
end

---Given scoring objects array return the score of all objects combined
---@param scoring_object_states ScoringObjectState[]
---@return number
function ScoringObjectState.aggrScore(scoring_object_states)
    local score = 0
    for _, scoring_object in ipairs(scoring_object_states) do
        score = score + scoring_object:getScore()
    end
    return score
end

---Given scoring objects array return the max score of all objects combined
---@param scoring_object_states ScoringObjectState[]
---@return number
function ScoringObjectState.aggrMaxScore(scoring_object_states)
    local score = 0
    for _, scoring_object in ipairs(scoring_object_states) do
        score = score + scoring_object:getMaxScore()
    end
    return score
end

---Given scoring objects array return average score to max score ratio
---only for scoring objects that are done
---@param scoring_object_states ScoringObjectState[]
---@return number
function ScoringObjectState.aggrAvgScore(scoring_object_states)
    local mult = 0
    local scoring_finished = 0
    for _, state in ipairs(scoring_object_states) do
        if state:isDone() and state:getMultiplier() ~= nil then
            mult = mult + state:getMultiplier()
            scoring_finished = scoring_finished + 1
        end
    end
    if scoring_finished == 0 then return 0 end
    mult = mult / scoring_finished
    return mult
end

local function test()
end
test()

return ScoringObjectState
