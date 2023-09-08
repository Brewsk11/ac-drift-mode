local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
local AsyncUtils = require('drift-mode/asynchelper')
local ConfigIO = require('drift-mode/configio')
local Timer = require('drift-mode/timer')
local PP = require('drift-mode/physicspatcher')
local S = require('drift-mode/serializer')

require('drift-mode/ui_layouts/scores')
require('drift-mode/ui_layouts/infobars')
require('drift-mode/models')

local config_list = ConfigIO.listTrackConfigs()

local listener_id = EventSystem.registerListener('dev-app')

---@type GameState
local game_state = GameState()

---@type CarConfig?
local car_data = nil

---@type TrackConfigInfo?
local track_config_info = nil

---@type TrackConfig?
local track_data = nil

---@type RunStateData?
local run_state_data = nil

local function loadCar()
  car_data = ConfigIO.loadCarConfig()
  if car_data == nil then car_data = CarConfig() end
  EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
end
loadCar()

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
else
  track_data = TrackConfig()
end
DataBroker.store("track_data", track_data)

---@type Cursor
local cursor_data = Cursor()
DataBroker.store("cursor_data", cursor_data)

local function teleportToStart()
  if physics.allowed() and track_data and track_data.startingPoint then
    physics.setCarPosition(
      0,
      track_data.startingPoint.origin:value(),
      track_data.startingPoint.direction * -1
    )
  else
    physics.teleportCarTo(0, ac.SpawnSet.HotlapStart)
  end
end

local collider_body = nil

local function reactivateColliders()
  --Needs to be in the application code as mode scripts do not allow creating RigidBody objects
  --Moreover, these would be hard to serialize, so the app script asks TrackConfig to list all
  --needed colliders, and the app scripts spawns and disposes of them.
  if collider_body then
    collider_body:setInWorld(false):dispose()
  end
  local colliders = track_data:gatherColliders()
  collider_body = physics.RigidBody(colliders, 1):setSemiDynamic(true, false)
end

local function listenForData()
  local changed = false
  EventSystem.startGroup()
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CursorChanged,      function (payload) cursor_data = payload end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TrackConfigChanged, function (payload) track_data = payload; reactivateColliders() end) or changed
  changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TeleportToStart,    function (payload) teleportToStart() end) or changed
  EventSystem.endGroup(changed)
end

local function refreshRunState()
  ---@type RunStateData
  run_state_data = DataBroker.read("run_state_data")
end

local running_task = nil
local is_helper_cam_active = false
local helper_cam = nil

local timers = {
  listeners = Timer(0.5, listenForData),
  run_state_refresher = Timer(0.05, refreshRunState)
}

---@diagnostic disable-next-line: duplicate-set-field
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

  if helper_cam then
    local car = ac.getCar(0)
    local cam_pos = car.position + vec3(0, 80, 0)
    helper_cam.transform.position:set(cam_pos)
    helper_cam.transform.side:set(car.side)
    helper_cam.transform.look:set(vec3(0, -1, 0))
    helper_cam.fov = 5
  end
end

local function gameStateUpdate()
  DataBroker.store("game_state", game_state)
  EventSystem.emit(EventSystem.Signal.GameStateChanged, game_state)
end

local function drawAppUI()
  -- [DECORATIVE] Car setup title text
  ui.pushFont(ui.Font.Title)
  ui.text("Car configuration")

  ui.offsetCursorY(5)

  -- [CHECKBOX] Enable configuration
  ui.pushFont(ui.Font.Main)
  if ui.checkbox("Show guides", game_state.isCarSetup) then
    game_state.isCarSetup = not game_state.isCarSetup
    gameStateUpdate()
  end

  -- [CHECKBOX] Enable helper camera
  ui.offsetCursor(vec2(120, -26))
  if ui.checkbox("Helper camera", is_helper_cam_active) then
    is_helper_cam_active = not is_helper_cam_active
    if is_helper_cam_active then helper_cam = ac.grabCamera("For car alignment") else helper_cam:dispose(); helper_cam = nil end
  end

  ui.offsetCursorY(15)

  -- [DECORATIVE] Front
  ui.pushFont(ui.Font.Title)
  ui.text("Front")

  -- [SLIDER] Front offset
  ui.pushFont(ui.Font.Monospace)
  ui.offsetCursor(vec2(65, -35))
  local value, changed = ui.slider("##foffset", car_data.frontOffset, 0.5, 3, 'Offset: %.2f')
  if changed then
    car_data.frontOffset = tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
    EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
  end

  -- [SLIDER] Front span
  ui.offsetCursorX(65)
  local value, changed = ui.slider("##fwidth", car_data.frontSpan, 0.05, 1.5, 'Span: %.2f')
  if changed then
    car_data.frontSpan =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
    EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
  end

  -- [DECORATIVE] Front
  ui.offsetCursorY(15)
  ui.pushFont(ui.Font.Title)
  ui.text("Rear")

  -- [SLIDER] Rear offset
  ui.pushFont(ui.Font.Monospace)
  ui.offsetCursor(vec2(65, -35))
  local value, changed = ui.slider("##roffset", car_data.rearOffset, 0.5, 3, 'Offset: %.2f')
  if changed then
    car_data.rearOffset =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
    EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
  end

  -- [SLIDER] Rear span
  ui.offsetCursorX(65)
  local value, changed = ui.slider("##rwidth", car_data.rearSpan, 0.05, 1.5, 'Span: %.2f')
  if changed then
    car_data.rearSpan =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
    EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
  end

  ui.offsetCursorY(15)

  -- [BUTTON] Save car config
  ui.pushFont(ui.Font.Main)
  if ui.button("Save ##saveCar", vec2(80, 30)) then
    ConfigIO.saveCarConfig(car_data)
  end

  -- [BUTTON] Reset car config
  ui.offsetCursor(vec2(90, -34))
  if ui.button("Reset ##resetCar", vec2(80, 30)) then
    loadCar()
  end

  -- [BUTTON] Reset car config
  ui.offsetCursor(vec2(180, -34))
  if ui.button("Open folder ##openCarDir", vec2(80, 30)) then
    os.openInExplorer(ac.getFolder(ac.FolderID.ExtCfgUser)  .. "\\drift-mode\\cars")
  end

  ui.offsetCursorY(20)
  ui.separator()
  ui.offsetCursorY(20)

  -- [DECORATIVE] Track patching section
  ui.pushFont(ui.Font.Title)
  ui.text("Track patcher")

  -- [DECORATIVE] Track patching help text
  ui.pushFont(ui.Font.Main)
  ui.text("For teleportation functionality track data has\nto be patched to use extended physics.")
  ui.text("After patching or restoring surfaces.ini\nrestart the game to apply changes.")
  ui.pushFont(ui.Font.Italic)
  ui.text("Note: this may lead to buggy collisions.")

  -- [BUTTON] Track patch button
  ui.pushFont(ui.Font.Main)
  local patch_button_label = "Patch track"
  if PP.isPatched() then patch_button_label = "Unpatch track" end
  if ui.button(patch_button_label, vec2(260, 30)) then
    if PP.isPatched() then
      PP.restore()
    else
      PP.patch()
    end
  end
end

function WindowMain()
  drawAppUI()
end

function WindowScores()
  appScoresLayout(run_state_data, game_state, track_data, scores_scale)
end

function WindowInfobars()
  if run_state_data and track_data then
    drawModifiers(track_data.scoringRanges, run_state_data.driftState)
  end
end

gameStateUpdate()
EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
