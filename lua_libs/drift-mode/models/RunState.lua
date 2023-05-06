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
        avgMultiplier = S.serialize(self:getAvgMultiplier()),
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

---@param car_config CarConfig
---@param car ac.StateCar
function RunState:registerCar(car_config, car)
    self:calcDriftState(car)

    self.driftState.ratio_mult = 0.0
    for _, zone in ipairs(self.zoneStates) do
        local res = zone:registerCar(car_config, car, self.driftState)
        if res ~= nil then
            self.driftState.ratio_mult = res
            break
        end
    end

    local clip_scoring_point = Point.new(
        car.position + car.look * car_config.frontOffset + car.side * car_config.frontSpan * -self.driftState.side_drifting
    )
    for _, clip in ipairs(self.clipStates) do
        clip:registerPosition(clip_scoring_point, self.driftState)
    end
end

---@param car ac.StateCar
function RunState:calcDriftState(car)
    local car_direction = vec3(0, 0, 0)
    car.velocity:normalize(car_direction)

    self.driftState.speed_mult = self.trackConfig.scoringRanges.speedRange:getFractionClamped(car.speedKmh)

    -- Somehow the dot sometimes is outside of the arccos domain, even though both v are normalized
    self.driftState.angle_mult = self.trackConfig.scoringRanges.angleRange:getFractionClamped(math.deg(math.acos(car_direction:dot(car.look))))

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
    for _, zone_state in ipairs(self.zoneStates) do
        score = score + zone_state:getScore()
    end
    for _, clip_state in ipairs(self.clipStates) do
        score = score + clip_state:getScore()
    end
    return score
end

function RunState:getAvgMultiplier()
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

    for _, clip_state in ipairs(self.clipStates) do
        clip_state:draw()
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
