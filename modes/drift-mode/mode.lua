local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener("mode")

local DataBroker = require('drift-mode/databroker')
local Timer = require('drift-mode/timer')
local ConfigIO = require('drift-mode/configio')
require('drift-mode/models')

local Teleporter = require('drift-mode/modes/Teleporter')

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
  track_config_info = track_cfg_info
  track_data = track_config_info:load()
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
end

track_config_info = ConfigIO.getLastUsedTrackConfigInfo()
if track_config_info then
  loadTrack(track_config_info)
elseif #config_list > 0 then
  loadTrack(config_list[1])
end

local function resetScore()
  if track_data then run_state = RunState(track_data) end
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

local drawerSetup = DrawerCourseSetup() ---@type DrawerCourseSetup
local drawerRun = DrawerRunStatePlay() ---@type DrawerRunStatePlay


local signalListeners = {
  {
    EventSystem.Signal.TrackConfigChanged,
    function(payload)
      track_data = payload
      if track_data ~= nil then
        run_state = RunState(track_data)
        reactivateColliders()
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
    function(payload) run_state = RunState(track_data) end
  },
  {
    EventSystem.Signal.CrossedFinish,
    function(payload) if run_state then run_state:setFinished(true) end end
  },
  {
    EventSystem.Signal.TeleportToStart,
    function(payload) Teleporter.teleportToStart(0, track_data) end
  }
}

local function listenForSignals()
  local changed = false
  EventSystem.startGroup()
  for _, v in ipairs(signalListeners) do
    changed = EventSystem.listenInGroup(listener_id, v[1], v[2]) or changed
  end
  EventSystem.endGroup(changed)

  -- Handle CrossedRespawn separately, as it wants to emit signal and probably
  -- should not be called in the group listening
  local crossed_respawn = false
  EventSystem.listen(listener_id, EventSystem.Signal.CrossedRespawn, function(_) crossed_respawn = true end)
  if crossed_respawn then
    EventSystem.emit(EventSystem.Signal.TeleportToStart, {})
  end
end


local function registerPosition()
  if not car_data or not run_state then return end

  local car = ac.getCar(0)

  run_state:registerCar(car_data, car)
end

local last_pos = nil
local function monitorCrossingLines()
  if not run_state or not track_data or not car_data then return end

  local car = ac.getCar(0)

  local current_pos = Point(car.position + car.look * car_data.frontOffset)
  if last_pos == nil then
    last_pos = current_pos
    return
  end

  -- If the delta is large then it was probably a teleport.
  -- Do not emit start/finish cross in such case.
  if last_pos:flat():distance(current_pos:flat()) > 5 then
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
    if res then EventSystem.emit(EventSystem.Signal.CrossedStart, {}) end
  end

  if track_data.finishLine then
    local res = vec2.intersect(
      track_data.finishLine.head:flat(),
      track_data.finishLine.tail:flat(),
      last_pos:flat(),
      current_pos:flat()
    )
    if res then EventSystem.emit(EventSystem.Signal.CrossedFinish, {}) end
  end

  if track_data.respawnLine then
    local res = vec2.intersect(
      track_data.respawnLine.head:flat(),
      track_data.respawnLine.tail:flat(),
      last_pos:flat(),
      current_pos:flat()
    )
    if res then EventSystem.emit(EventSystem.Signal.CrossedRespawn, {}) end
  end

  last_pos = current_pos
end

local timers = {
  data_brokered = Timer(0.02, function() listenForSignals() end),
  scoring_player = Timer(0.05, function()
    if run_state and editors_state and not editors_state:anyEditorEnabled() then
      registerPosition()
      DataBroker.store("run_state_data", run_state)
    end
  end),
  monitor_crossing = Timer(0.1, function()
    monitorCrossingLines()
  end)
}


local running_task = nil

function script.update(dt)
  for _, timer in pairs(timers) do
    timer:tick(dt)
  end

  if running_task ~= nil then
    coroutine.resume(running_task)
    if coroutine.status(running_task) == 'dead' then
      running_task = nil
    end
  end

  ac.debug("physics.allowed()", physics.allowed())

  if ac.getCar(0).extraF then
    ac.setExtraSwitch(5, false)
    EventSystem.emit(EventSystem.Signal.TeleportToStart, {})
  end

  if not run_state and track_data then run_state = RunState(track_data) end
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
