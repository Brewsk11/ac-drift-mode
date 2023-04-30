local user_cfg_path = os.getenv("USERPROFILE") .. "\\Documents\\Assetto Corsa\\cfg\\extension\\drift-mode"

local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
local AsyncUtils = require('drift-mode/asynchelper')
local ConfigIO = require('drift-mode/configio')
local S = require('drift-mode/serializer')
require('drift-mode/models')

local config_list = ConfigIO.listTrackConfigs()

local listener_id = EventSystem.registerListener('dev-app')

---@type GameState
local game_state = GameState.new()

---@type CarConfig
local car_data = nil

---@type TrackConfig?
local track_data = nil

local new_zone_name = nil
local new_clip_name = nil
local combo_selected = nil
local combo_selected_type = nil

local function loadCar()
  car_data = ConfigIO.loadCarConfig()
  if car_data == nil then car_data = CarConfig.new() end
  EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
end
loadCar()

local function loadTrack(track_cfg_name, dir)
  track_data = ConfigIO.loadTrackConfig(track_cfg_name, dir)
  new_zone_name = track_data:getNextZoneName()
  new_clip_name = track_data:getNextClipName()
  combo_selected = track_data.name
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
end

if #config_list.user_configs > 0 then
  loadTrack(config_list.user_configs[1])
elseif #config_list.official_configs > 0 then
  loadTrack(config_list.official_configs[1], "official")
else
  track_data = TrackConfig.new()
  new_zone_name = track_data:getNextZoneName()
  new_clip_name = track_data:getNextClipName()
end
DataBroker.store("track_data", track_data)

---@type Cursor
local cursor_data = Cursor.new()
DataBroker.store("cursor_data", cursor_data)

local data_listener_timer = 0
local data_listener_period = 0.5

local function listenForData()
  EventSystem.listen(listener_id, EventSystem.Signal.CursorChanged,      function (payload) cursor_data = payload end)
  EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function (payload) track_data = payload end)
end

local running_task = nil
local is_helper_cam_active = false
local helper_cam = nil

local track_buttons_flags = ui.ButtonFlags.None
local track_inputs_flags = ui.InputTextFlags.None

function script.update(dt)
  data_listener_timer = data_listener_timer + dt
  if data_listener_timer > data_listener_period then
    data_listener_timer = 0
    listenForData()
  end

  if running_task ~= nil then
    coroutine.resume(running_task)
    if coroutine.status(running_task) == 'dead' then
      running_task = nil
    end
  end

  if ac.getCar(0).extraF then
    physics.teleportCarTo(0, ac.SpawnSet.HotlapStart)
    ac.setExtraSwitch(5, false)
    EventSystem.emit(EventSystem.Signal.Restart, {})
  end

  if helper_cam then
    local car = ac.getCar(0)
    local cam_pos = car.position + vec3(0, 80, 0)
    helper_cam.transform.position:set(cam_pos)
    helper_cam.transform.side:set(car.side)
    helper_cam.transform.look:set(vec3(0, -1, 0))
    helper_cam.fov = 5
  end

  if not game_state.isTrackSetup or running_task then
    track_buttons_flags = ui.ButtonFlags.Disabled
    track_inputs_flags = ui.InputTextFlags.ReadOnly
  else
    track_buttons_flags = ui.ButtonFlags.None
    track_inputs_flags = ui.InputTextFlags.None
  end
end

local function cursorReset()
  cursor_data:reset()
  DataBroker.store("cursor_data", cursor_data)
  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

local function cursorUpdate()
  DataBroker.store("cursor_data", cursor_data)
  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

local function gameStateUpdate()
  DataBroker.store("game_state", game_state)
  EventSystem.emit(EventSystem.Signal.GameStateChanged, game_state)
end

local createZone = function ()
  local outsidePoints = AsyncUtils.runTask(AsyncUtils.taskGatherPointGroup); listenForData()
  cursor_data.point_group_b = outsidePoints
  if not outsidePoints then cursorReset(); return else cursorUpdate() end

  local insidePoints = AsyncUtils.runTask(AsyncUtils.taskGatherPointGroup); listenForData()
  if not insidePoints then cursorReset(); return end

  local zone = Zone.new(new_zone_name, outsidePoints, insidePoints, 2000)
  track_data.zones[#track_data.zones+1] = zone
  new_zone_name = track_data:getNextZoneName()
  DataBroker.store("track_data", track_data)
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

  cursorReset()
end

local createClippingPoint = function()
  ---@type Point
  local origin = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  cursor_data.point_group_b = PointGroup.new({origin})
  cursor_data.color_selector = rgbm(0, 2, 1, 1)
  if not origin then cursorReset(); return else cursorUpdate() end

  ---@type Point
  local _end = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  if not origin then cursorReset(); return end

  local direction = (_end:value() - origin:value()):normalize()
  local length = _end:value():distance(origin:value())

  local clippingPoint = ClippingPoint.new(new_clip_name, origin, direction, length, 1000)
  track_data.clippingPoints[#track_data.clippingPoints+1] = clippingPoint
  new_clip_name = track_data:getNextClipName()
  DataBroker.store("track_data", track_data)
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

  cursorReset()
end

local createStartLine = function()
  ---@type Point
  local origin = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  cursor_data.point_group_a = PointGroup.new({Point.new("", origin)})
  cursor_data.color_selector = rgbm(0, 2, 1, 1)
  if not origin then cursorReset(); return else cursorUpdate() end

  ---@type Point
  local _end = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  if not _end then cursorReset(); return end

  local startLine = Segment.new(origin, _end)
  track_data.startLine = startLine
  DataBroker.store("track_data", track_data)
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

  cursorReset()
end

local createFinishLine = function()
  ---@type Point
  local origin = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  cursor_data.point_group_a = PointGroup.new({Point.new("", origin)})
  cursor_data.color_selector = rgbm(0, 2, 1, 1)
  if not origin then cursorReset(); return else cursorUpdate() end

  ---@type Point
  local _end = AsyncUtils.runTask(AsyncUtils.taskGatherPoint); listenForData()
  if not _end then cursorReset(); return end

  local startLine = Segment.new(origin, _end)
  track_data.finishLine = startLine
  DataBroker.store("track_data", track_data)
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

  cursorReset()
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

  ui.offsetCursorY(30)
  ui.separator()
  ui.offsetCursorY(30)

  -- [DECORATIVE] Track setup title text
  ui.pushFont(ui.Font.Title)
  ui.text("Track configuration")

  ui.pushFont(ui.Font.Main)
  if ui.checkbox("Enable track configuration", game_state.isTrackSetup) then
    game_state.isTrackSetup = not game_state.isTrackSetup
    gameStateUpdate()
  end

  ui.pushFont(ui.Font.Monospace)
  ui.offsetCursorY(10)

  -- [INPUT] Track config name text box
  ui.setNextItemWidth(175)
  local text, changed = ui.inputText("##configName", track_data.name, track_inputs_flags)
  if changed then track_data.name = text end

  -- [COMBO] Track config combo box
  ui.setNextItemWidth(175)
  ui.combo("##configDropdown", combo_selected, function ()
    config_list = ConfigIO.listTrackConfigs(ac.getTrackID())
    for _, cfg in ipairs(config_list.user_configs) do
      if ui.selectable("    [User] " .. cfg, cfg) then
        combo_selected = cfg
        combo_selected_type = nil
      end
    end
    for _, cfg in ipairs(config_list.official_configs) do
      if ui.selectable("[Official] " .. cfg, cfg) then
        combo_selected = cfg
        combo_selected_type = "official"
      end
    end
  end)

  -- [BUTTON] Save track config button
  ui.pushFont(ui.Font.Small)
  ui.offsetCursor(vec2(200, -48))
  if ui.button("Save ##saveTrack", vec2(60, 20), track_buttons_flags) then
    ConfigIO.saveTrackConfig(track_data)
    combo_selected = track_data.name
    config_list = ConfigIO.listTrackConfigs()
  end

  -- [BUTTON] Load track config button
  ui.offsetCursor(vec2(200, 0))
  if ui.button("Load", vec2(60, 20), track_buttons_flags) then
    if combo_selected == nil then return end
    track_data = ConfigIO.loadTrackConfig(combo_selected, combo_selected_type)
    EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
  end

  ui.offsetCursorY(15)
  ui.separator()
  ui.offsetCursorY(15)

  -- [BUTTON] Create zone
  ui.pushFont(ui.Font.Main)
  if ui.button("Create zone", vec2(120, 50), track_buttons_flags) then
    running_task = coroutine.create(createZone)
  end

  -- [BUTTON] Create clipping point
  ui.offsetCursor(vec2(140, -54))
  if ui.button("Create clip", vec2(120, 50), track_buttons_flags) then
    running_task = coroutine.create(createClippingPoint)
  end

  -- [INPUT] Zone name
  ui.pushFont(ui.Font.Monospace)
  ui.setNextItemWidth(120)
  local text, changed = ui.inputText("##zoneName", new_zone_name, track_inputs_flags)
  if changed then new_zone_name = text end

  -- [INPUT] Clipping point name
  ui.offsetCursor(vec2(140, -24))
  ui.setNextItemWidth(120)
  local text, changed = ui.inputText("##clipName", new_clip_name, track_inputs_flags)
  if changed then new_clip_name = text end

  ui.offsetCursorY(15)

  -- [BUTTON] Create start line
  ui.pushFont(ui.Font.Main)
  if ui.button("Create start line", vec2(120, 50), track_buttons_flags) then
    running_task = coroutine.create(createStartLine)
  end

  -- [BUTTON] Create finish line
  ui.offsetCursor(vec2(140, -54))
  if ui.button("Create finish line", vec2(120, 50), track_buttons_flags) then
    running_task = coroutine.create(createFinishLine)
  end

  ui.offsetCursorY(20)
  ui.separator()
  ui.offsetCursorY(20)


  -- [BUTTON] Clear track
  ui.pushFont(ui.Font.Main)
  if ui.button("Clear the track", vec2(120, 30), track_buttons_flags) then
    local prev_track_config_name = track_data.name
    track_data = TrackConfig.new()
    track_data.name = prev_track_config_name
    new_zone_name = track_data:getNextZoneName()
    new_clip_name = track_data:getNextClipName()
    EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
  end

  -- [BUTTON] Open config directory
  ui.offsetCursor(vec2(140, -34))
  if ui.button("Open configs dir", vec2(120, 30)) then
    local usr_cfg_path = ac.getFolder(ac.FolderID.ExtCfgUser)  .. "\\drift-mode"
    local usr_configs = usr_cfg_path .. "\\tracks\\" .. ac.getTrackID()
    os.openInExplorer(usr_configs)
  end
end


function WindowMain()
  drawAppUI()
end

gameStateUpdate()
EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
