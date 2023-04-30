local EventSystem = require('drift-mode/eventsystem')
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

local max_angle = 60
local min_angle = 5

local max_speed = 100
local min_speed = 15

local total_score = 0

local listener_id = EventSystem.registerListener("drift-mode-dev")

local function calcMultipliers()
  local car = ac.getCar(0)
  local car_direction = car.velocity:clone():normalize()

  -- Speed
  current_speed = car.speedKmh
  local scoring_speed = math.clamp(current_speed, min_speed, max_speed)
  mult_speed = (scoring_speed - min_speed) / (max_speed - min_speed)

  -- Angle
  current_angle = math.deg(math.acos(car_direction:dot(car.look)))
  local scoring_angle = math.clamp(current_angle, min_angle, max_angle)
  mult_angle = (scoring_angle - min_angle) / (max_angle - min_angle)

  if mult_speed == 0 then -- Clamp angle when stationary
    mult_angle = 0
  else
    mult_angle = (scoring_angle - min_angle) / (max_angle - min_angle)
  end

  return mult_speed, mult_angle
end

local function restartRun()
  if track_data then run_state = RunState.new(track_data) end
  total_score = 0
end

local function listenForSignals()
  local changed = false
  EventSystem.startGroup()
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CursorChanged,      function (payload) cursor_data = payload end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TrackConfigChanged, function (payload) track_data = payload; run_state = RunState.new(track_data) end)  or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CarConfigChanged,   function (payload) car_data = payload end)    or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.GameStateChanged,   function (payload) game_state = payload end)  or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.Restart,            function (payload) restartRun() end)          or changed
  EventSystem.endGroup(changed)
end

local function registerPosition()
  if not car_data or not run_state then return end

  local car = ac.getCar(0)
  local car_scoring_point = Point.new("", car.position + (-car.look * car_data.rearOffset))

  current_speed, current_angle = calcMultipliers()
  if run_state then
    current_ratio = run_state:registerPosition(car_scoring_point, current_speed, current_angle)
  end
end

local timers = {
  data_brokered = Timer.new(0.02, function () listenForSignals() end),
  scoring_player = Timer.new(0.1, function ()
    if run_state and game_state and game_state:isPlaymode() then
      registerPosition()
      total_score = run_state:getScore()
    end
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

  local car = ac.getCar(0)

  if game_state and not game_state:isPlaymode() then
    if track_data then track_data:drawSetup() end
    if cursor_data then cursor_data:draw() end
  else
    if run_state then run_state:draw() end
  end
end

local function drawModifiers()
  -- local mult_speed = cursor_data.dspeed
  -- local mult_angle = cursor_data.dangle
  -- local current_ratio = cursor_data.dratio

  local speedRect = {
    origin = vec2(0, 0),
    size = vec2(300, 25),
    min = min_speed,
    max = max_speed,
    name = "Speed",
    color = rgbm(230 / 255, 138 / 255, 46 / 255, 1)
  }

  local angleRect = {
    origin = vec2(0, 30),
    size = vec2(300, 25),
    min = min_angle,
    max = max_angle,
    name = "Angle",
    color = rgbm(20 / 255, 204 / 255, 112 / 255, 1)
  }

  local ratioRect = {
    origin = vec2(0, 60),
    size = vec2(300, 25),
    min = 0,
    max = 100,
    name = "Zone depth",
    color = rgbm(112 / 255, 20 / 255, 204 / 255, 1)
  }

  local compoundRect = {
    origin = vec2(0, 100),
    size = vec2(300, 30),
    min = 0,
    max = 100,
    name = "Score multiplier",
    color = rgbm(180 / 255, 180 / 255, 180 / 255, 1)
  }

  local windowWidth = ui.windowWidth()
  local widgetSize = vec2(300, 130)
  local widgetOrigin = vec2(windowWidth / 2 - widgetSize.x / 2, 200)

  local function drawInfobar(rect, value)
    if value == nil then return end
    ui.drawRect(rect.origin, rect.origin +  rect.size, rect.color, 2)

    if value ~= nil then
      ui.drawRectFilled(rect.origin, rect.origin +  vec2(rect.size.x * value, rect.size.y), rect.color, 2)
      ui.setCursor(rect.origin)
      ui.dwriteTextAligned(rect.name, 10, ui.Alignment.Start, ui.Alignment.End, rect.size)
      ui.setCursor(rect.origin)
      ui.dwriteTextAligned(string.format("%.0f%%", value * 100), 18, ui.Alignment.Center, ui.Alignment.Center, rect.size)
    end

    ui.setCursor(rect.origin)
    ui.dwriteTextAligned(rect.min, 10, ui.Alignment.Start, ui.Alignment.Start, rect.size)
    ui.setCursor(rect.origin)
    ui.dwriteTextAligned(rect.max, 10, ui.Alignment.End, ui.Alignment.End, rect.size)
  end

  local ratio_nil = current_ratio
  if current_ratio == nil then ratio_nil = 0 end

  ui.beginTransparentWindow('modifiers', widgetOrigin, widgetSize, true)
  ui.pushDWriteFont("ACRoboto700.ttf")
  drawInfobar(speedRect, mult_speed)
  drawInfobar(angleRect, mult_angle)
  drawInfobar(ratioRect, ratio_nil)
  if mult_angle and mult_speed then
    drawInfobar(compoundRect, mult_speed * mult_angle * ratio_nil)
  end
  ui.endTransparentWindow()
end

function script.drawUI()
  ui.beginTransparentWindow('logo', vec2(510, 110), vec2(50, 50), true)
  ui.image("logo white.png", vec2(50, 50), true)
  ui.endTransparentWindow()

  if not run_state or not game_state then return end

  if game_state:isPlaymode() then
    local orig = vec2(15, 10)

    drawModifiers()

    local window_height = 165 + #run_state.zoneStates * 20
    ui.beginToolWindow('scoresWindow', vec2(150, 100), vec2(420, window_height), false)
    ui.setCursor(orig)
    ui.pushFont(ui.Font.Main)
    ui.text(track_data.name)
    ui.offsetCursorY(-10)
    ui.pushFont(ui.Font.Huge)
    ui.text(string.format("Total score: %.0f", total_score))
    ui.pushFont(ui.Font.Main)
    ui.offsetCursorY(-10)
    ui.text(string.format("Total performance: %.2f%%", run_state:getPerformance() * 100))
    ui.offsetCursorY(20)
    local header_orig = ui.getCursor()
    ui.pushFont(ui.Font.Main)
    ui.text("Zone")
    ui.setCursor(header_orig + vec2(150, 0))
    ui.text("Score")
    ui.setCursor(header_orig + vec2(200, 0))
    ui.text("Mult.")
    ui.setCursor(header_orig + vec2(250, 0))
    ui.text("Max")
    ui.setCursor(header_orig + vec2(300, 0))
    ui.text("Sampl.")
    ui.setCursor(header_orig + vec2(350, 0))
    ui.text("Done")
    ui.offsetCursorY(10)
    ui.pushFont(ui.Font.Monospace)
    for _, zone_state in ipairs(run_state.zoneStates) do
      local zone_orig = ui.getCursor()
      ui.text(zone_state.zone.name)
      ui.setCursor(zone_orig + vec2(150, 0))
      ui.text(string.format("%.0f", zone_state:getScore()))
      ui.setCursor(zone_orig + vec2(200, 0))
      ui.text(tostring(zone_state.zone.maxPoints))
      ui.setCursor(zone_orig + vec2(250, 0))
      ui.text(string.format("%.2f%%", zone_state:getMultiplier() * 100))
      ui.setCursor(zone_orig + vec2(300, 0))
      ui.text(string.format(#zone_state.scores))
      ui.setCursor(zone_orig + vec2(350, 0))
      local done = "-"
      if zone_state:isFinished() then done = "X" end
      ui.text(done)
    end
    ui.endToolWindow()
  else
    ui.beginToolWindow('helpWindow', vec2(150, 100), vec2(420, 600), false)
    ui.pushFont(ui.Font.Huge)
    ui.text("Help")
    ui.pushFont(ui.Font.Main)
    ui.text("By default the game loads first found user track config,\nand if not exists then first \"official\" track config\n(shipped with the mod)")
    ui.text("To bind a key to restart a drift run bind \"Extra option F\"\nin Content Mananger controls menu.")
    ui.pushFont(ui.Font.Title)
    ui.text("Creating zones:")
    ui.pushFont(ui.Font.Main)
    ui.text("Trace the outside line first, then after confirming\ntrace the inside line IN THE SAME DIRECTION.\nThis is important to correctly calculate scoring.")
    ui.text("S - place point\nQ - undo\nA - cancel\nF - confirm")
    ui.pushFont(ui.Font.Title)
    ui.text("Scoring:")
    ui.pushFont(ui.Font.Main)
    ui.text("Scoring system does not count time spent in a zone\nbut the overall performance in the zone. This can be cheesed easily\nnow, but will be improved.")
    ui.pushFont(ui.Font.Title)
    ui.text("Limitations:")
    ui.pushFont(ui.Font.Main)
    ui.text("Clipping points and start/finish lines are not supported for now.")
    ui.text("In some future release crossing the finish line\nwill also restart the run.")
    ui.text("Car alignment: front settings and rear span do not matter\nfor now. In this release the scoring point is at the center\nof the rear bumper.")
    ui.text("More features and improvements are planned.\nCheck out RaceDepartment and Github pages for updates.")
    ui.text("Thanks for playing!")
    ui.endToolWindow()
  end
end
