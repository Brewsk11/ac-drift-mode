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

    EventSystem.queue(EventSystem.Signal.ScoringObjectStatesReset, self.scoringObjectStates)
end

---Serializes to lightweight RunStateData as RunState should not be brokered.
---@param self RunState
---@return table
function RunState:__serialize()
    local data = {
        __class = "RunStateData",
        scoringObjectStates = S.serialize(self.scoringObjectStates),
        driftState = S.serialize(self.driftState),
        totalScore = S.serialize(self:getScore()),
        maxScore = S.serialize(self:getMaxScore()),
        avgMultiplier = S.serialize(self:getAvgMultiplier()),
    }

    return data
end

---@param car_config CarConfig
---@param car ac.StateCar
function RunState:registerCar(car_config, car)
    self:calcDriftState(car)

    self.driftState.ratio_mult = 0.0
    for idx, scoring_object in ipairs(self.scoringObjectStates) do
        if scoring_object.isInstanceOf(ZoneState) then
            ac.log("looking at " .. idx)
            local res = scoring_object:registerCar(car_config, car, self.driftState)
            ac.debug("res", res)
            if res ~= nil then
                self.driftState.ratio_mult = res
                EventSystem.queue(EventSystem.Signal.ScoringObjectStateChanged,
                    {
                        idx = idx,
                        type = "ZoneState",
                        scoring_object_state_delta = scoring_object.scores[#scoring_object.scores]
                    })
                ac.log("sending idx " .. idx)
                break
            end
        elseif scoring_object.isInstanceOf(ClipState) then
            local clip_scoring_point = Point(
                car.position + car.look * car_config.frontOffset +
                car.side * car_config.frontSpan * -self.driftState.side_drifting
            )
            scoring_object:registerPosition(clip_scoring_point, self.driftState)
            EventSystem.queue(EventSystem.Signal.ScoringObjectStateChanged,
                { idx = idx, type = "ClipState", scoring_object_state = scoring_object })
        else
            Assert.Error("")
        end
    end

    EventSystem.queue(EventSystem.Signal.DriftStateChanged, self.driftState)
end

---@param car ac.StateCar
function RunState:calcDriftState(car)
    local car_direction = vec3(0, 0, 0)
    car.velocity:normalize(car_direction)

    self.driftState.speed_mult = self.trackConfig.scoringRanges.speedRange:getFractionClamped(car.speedKmh)

    -- TODO: Somehow the dot sometimes is outside of the arccos domain, even though both v are normalized
    -- For now run additional check not to dirty the logs
    local car_angle = math.deg(math.acos(car_direction:dot(car.look)))
    if car_angle == car_angle then -- Check if nan
        self.driftState.angle_mult = self.trackConfig.scoringRanges.angleRange:getFractionClamped(car_angle)
    end

    -- Ignore angle when min speed not reached, to avoid big fluctuations with low speed
    if self.driftState.speed_mult == 0 then
        self.driftState.angle_mult = 0
    end

    local dot = car.velocity:dot(car.side)
    if dot > 0 then
        self.driftState.side_drifting = DriftState.Side.LeftLeads
    else
        self.driftState.side_drifting = DriftState.Side.RightLeads
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
