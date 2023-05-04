local EventSystem = require('drift-mode/eventsystem')
local DataBroker = require('drift-mode/databroker')
local Timer = require('drift-mode/timer')
local S = require('drift-mode/serializer')
require('drift-mode/models')

---@type TrackConfig?
local track_data = nil

---@type Cursor?
local cursor_data = nil

---@type CarConfig?
local car_data = nil

---@type GameState?
local game_state = nil

---@type RunState?
local run_state = nil

local current_ratio = nil
local current_angle = nil
local current_speed = nil
local mult_angle = nil
local mult_speed = nil

local listener_id = EventSystem.registerListener("drift-mode-dev")

local function calcMultipliers()
  if not track_data then return end

  local car = ac.getCar(0)
  local car_direction = car.velocity:clone():normalize()

  mult_speed = track_data.scoringRanges.speedRange:getFractionClamped(car.speedKmh)
  mult_angle = track_data.scoringRanges.angleRange:getFractionClamped(math.deg(math.acos(car_direction:dot(car.look))))

  -- Ignore angle when min speed not reached, to avoid big fluctuations with low speed
  if car.speedKmh < 30 then  mult_angle = 0 end

  return mult_speed, mult_angle
end

local function resetScore()
  if track_data then run_state = RunState.new(track_data) end
end

local function listenForSignals()
  local changed = false
  EventSystem.startGroup()
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CursorChanged,      function (payload) cursor_data = payload end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TrackConfigChanged, function (payload) track_data = payload; run_state = RunState.new(track_data) end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CarConfigChanged,   function (payload) car_data = payload end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.GameStateChanged,   function (payload) game_state = payload end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.ResetScore,         function (_      ) resetScore() end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CrossedStart,       function (_      ) run_state = RunState.new(track_data) end) or changed
  EventSystem.endGroup(changed)
  local crossed_finish = false
  EventSystem.listen(listener_id, EventSystem.Signal.CrossedFinish, function (_) crossed_finish = true
  end)
  if crossed_finish then
    EventSystem.emit(EventSystem.Signal.TeleportToStart, {})
  end
end

local function registerPosition()
  if not car_data or not run_state then return end

  local car = ac.getCar(0)
  local car_scoring_point = Point.new(car.position + (-car.look * car_data.rearOffset))

  current_speed, current_angle = calcMultipliers()
  if run_state then
    current_ratio = run_state:registerPosition(car_scoring_point, current_speed, current_angle)
  end
end

local last_pos = nil
local function monitorCrossingLines()
  if not run_state or not track_data then return end

  local current_pos = Point.new(ac.getCar(0).position)
  if last_pos == nil then
    last_pos = current_pos
    return
  end

  if track_data.startLine then
    local res = vec2.intersect(
      track_data.startLine.head:flat(),
      track_data.startLine.tail:flat(),
      last_pos:flat(),
      current_pos:flat()
    )
    if res then ac.log("emitting start");  EventSystem.emit(EventSystem.Signal.CrossedStart, {}) end
  end

  if track_data.finishLine then
    local res = vec2.intersect(
      track_data.finishLine.head:flat(),
      track_data.finishLine.tail:flat(),
      last_pos:flat(),
      current_pos:flat()
    )
    if res then ac.log("emitting finish"); EventSystem.emit(EventSystem.Signal.CrossedFinish, {}) end
  end

  last_pos = current_pos
end

local timers = {
  data_brokered = Timer.new(0.02, function () listenForSignals() end),
  scoring_player = Timer.new(0.1, function ()
    if run_state and game_state and game_state:isPlaymode() then
      registerPosition()
      total_score = run_state:getScore()
    end
  end),
  monitor_crossing = Timer.new(0.1, function()
    monitorCrossingLines()
  end),
  emit_run_state = Timer.new(0.05, function()
    DataBroker.store("run_state_data", run_state)
    DataBroker.store('drift_state', DriftState.new(mult_speed, mult_angle, current_ratio))
  end)
}

function script.update(dt)
  for _, timer in pairs(timers) do
    timer:tick(dt)
  end

  if not run_state and track_data then run_state = RunState.new(track_data) end
end

function script.draw3D()
  if car_data and game_state and game_state.isCarSetup then car_data:drawAlignment() end

  if game_state and not game_state:isPlaymode() then
    if track_data then track_data:drawSetup() end
    if cursor_data then cursor_data:draw() end
  else
    if run_state then run_state:draw() end
  end
end

function script.drawUI()
  if not run_state or not game_state then return end
end
