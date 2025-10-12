local EventSystem = require('drift-mode.eventsystem')
local listener_id = EventSystem.registerListener("mode")

local Timer = require('drift-mode.timer')
local ConfigIO = require('drift-mode.configio')
local Point = require("drift-mode.models.Common.Point.Point")
local Circle = require("drift-mode.models.Common.Circle")
local Arc = require("drift-mode.models.Common.Arc.Arc")



local Cursor = require("drift-mode.models.Editor.Cursor")
local Course = require("drift-mode.models.Elements.Course.init")
local TrackConfig = Course.TrackConfig
local RunState = Course.RunState

local Teleporter = require('drift-mode.modes.Teleporter')
local LineCrossDetector = require('drift-mode.modes.LineCrossDetector')

local TestHarness = require('drift-mode.TestHarness')
TestHarness:runTesting()

local config_list = ConfigIO.listTrackConfigs()

---@type Cursor
local cursor_data = Cursor()
EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)

---@type CarConfig?
local car_data = nil

---@type EditorsState?
local editors_state = nil

---@type RunState?
local run_state = nil

---@type TrackConfigInfo?
local track_config_info = nil

---@type TrackConfig?
local track_data = TrackConfig()


---@param track_cfg_info TrackConfigInfo
local function loadTrack(track_cfg_info)
  track_data = ConfigIO.loadTrackConfig(track_cfg_info)
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
end

track_config_info = ConfigIO.getLastUsedTrackConfigInfo()
if track_config_info then
  loadTrack(track_config_info)
elseif #config_list > 0 then
  loadTrack(config_list[1])
end

local function resetScore()
  if track_data then
    run_state = RunState(track_data)
  end
end


local collider_body = nil

local noPhysicsInfo = false

local function reactivateColliders()
  -- Function probably broken between 0.1.79 : 0.2.5
  if not physics.allowed() then
    if not noPhysicsInfo then
      ac.setMessage(
        "Extended physics unavailable",
        "Colliders or teleportation won't work. Consider patching the track from the control panel."
      )
      noPhysicsInfo = true
    end
    return
  end

  if not track_data then return end

  if collider_body then
    collider_body:setInWorld(false):dispose()
  end
  local colliders = track_data:gatherColliders()
  collider_body = physics.RigidBody(colliders, 1):setSemiDynamic(true, false)
end

local drawerSetup = Course.Drawers.DrawerCourseSetup() ---@type DrawerCourseSetup
local drawerRun = Course.Drawers.DrawerRunStatePlay() ---@type DrawerRunStatePlay


local signalListeners = {
  {
    EventSystem.Signal.TrackConfigChanged,
    function(payload)
      track_data = payload
      if track_data ~= nil then
        EventSystem.emit(EventSystem.Signal.ResetScore)
        reactivateColliders()

        LineCrossDetector.clear()
        if track_data.startLine then
          LineCrossDetector.registerLine(track_data.startLine,
            EventSystem.Signal.CrossedStart, 5)
        end
        if track_data.finishLine then
          LineCrossDetector.registerLine(track_data.finishLine,
            EventSystem.Signal.CrossedFinish, 5)
        end
        if track_data.respawnLine then
          LineCrossDetector.registerLine(track_data.respawnLine,
            EventSystem.Signal.CrossedRespawn, 5)
        end
      end
    end
  },
  {
    EventSystem.Signal.CursorChanged,
    function(payload) cursor_data = payload end
  },
  {
    EventSystem.Signal.CarConfigChanged,
    function(payload) car_data = payload end
  },
  {
    EventSystem.Signal.EditorsStateChanged,
    function(payload) editors_state = payload end
  },
  {
    EventSystem.Signal.ResetScore,
    function(payload) resetScore() end
  },
  {
    EventSystem.Signal.CrossedStart,
    function(payload) EventSystem.emit(EventSystem.Signal.ResetScore) end
  },
  {
    EventSystem.Signal.CrossedFinish,
    function(payload) if run_state then run_state:setFinished(true) end end
  },
  {
    EventSystem.Signal.TeleportToStart,
    function(payload) Teleporter.teleportToStart(0, track_data) end
  },
  {
    EventSystem.Signal.CrossedRespawn,
    function(payload) EventSystem.emit(EventSystem.Signal.TeleportToStart) end
  }
}

local function listenForSignals()
  for _, v in ipairs(signalListeners) do
    EventSystem.listen(listener_id, v[1], v[2])
  end
end


local function registerPosition()
  if not car_data or not run_state then return end

  local car = ac.getCar(0)

  run_state:registerCar(car_data, car)
end

local timers = {
  data_brokered = Timer(0.05, function() listenForSignals() end),
  scoring_player = Timer(0.05, function()
    if run_state and editors_state and not editors_state:anyEditorEnabled() then
      registerPosition()
    end
  end),
  refresh_driftstate = Timer(0.01, function()
    if run_state and editors_state and not editors_state:anyEditorEnabled() then
      run_state:calcDriftState(ac.getCar(0))
    end
  end),
  monitor_crossing = Timer(0.1, function()
    if not run_state or not track_data or not car_data then return end
    local car = ac.getCar(0)
    local current_pos = Point(car.position + car.look * car_data.frontOffset)
    LineCrossDetector.registerPoint(current_pos)
  end)
}


---@diagnostic disable-next-line duplicate-set-field
function script.update(dt)
  for _, timer in pairs(timers) do
    timer:tick(dt)
  end

  ac.debug("physics.allowed()", physics.allowed())

  if ac.getCar(0).extraF then
    ac.setExtraSwitch(5, false)
    EventSystem.emit(EventSystem.Signal.TeleportToStart, {})
  end

  if not run_state and track_data then resetScore() end
end

function script.draw3D()
  if car_data and editors_state and editors_state.isCarSetup then car_data:drawAlignment() end

  if editors_state and editors_state:anyEditorEnabled() then
    if track_data then drawerSetup:draw(track_data) end
    if cursor_data then cursor_data:draw() end
  else
    if run_state then drawerRun:draw(run_state) end
  end
end

function script.drawUI()
end
