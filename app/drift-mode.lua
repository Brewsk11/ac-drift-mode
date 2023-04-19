local json = require('drift-mode/json')

local user_cfg_path = os.getenv("USERPROFILE") .. "\\Documents\\Assetto Corsa\\cfg\\extension\\drift-mode"

local DataBroker = require('drift-mode/databroker')
local ConfigIO = require('drift-mode/configio')

local car_cfg_path = user_cfg_path .. '\\' .. ac.getCarID(0) .. '.ini'
local track_cfg_path = user_cfg_path .. '\\' .. ac.getTrackID() .. '.ini'

local car_data = nil
local track_data = nil
local cursor_data = {
  show_wireframe = false
}

local function loadCarSetup()
  car_data = ConfigIO.loadConfig(car_cfg_path)
  if car_data == nil then
    car_data = {
      front_offset = 2.3,
      front_span = 1,
      rear_offset = 2.4,
      rear_span = 1
    }
  end
  DataBroker.store("car_data", car_data)
end

local function loadTrackSetup()
  track_data = ConfigIO.loadConfig(track_cfg_path)
  if track_data == nil then
    track_data = {}
  end
  DataBroker.store("track_data", track_data)
end

local function saveTrackSetup()
  ConfigIO.saveConfig(track_cfg_path, track_data)
  loadTrackSetup()
end

local function saveCarSetup()
  ConfigIO.saveConfig(car_cfg_path, car_data)
  loadCarSetup()
end

loadCarSetup()
loadTrackSetup()

function waitForRelease(key_index)
  while true do
    if ui.keyboardButtonReleased(key_index) then
      break
    end
    coroutine.yield(nil)
  end
end

local createClippingPoint = (function ()
  local hit = vec3()

  -- Find count of clipping points
  local clipping_point_count = 0
  for name, _ in pairs(track_data) do
    if string.startsWith(name, "clipping_point_") then
      local no = tonumber(string.gsub(name, "clipping_point_", ""), 10)
      if no > clipping_point_count then clipping_point_count = no end
    end
  end
  local clipping_point_number = clipping_point_count + 1

  cursor_data.selector = { position = hit }

  while true do
    local ray = render.createMouseRay()
    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

      if ui.keyboardButtonPressed(ui.KeyIndex.S) then
        cursor_data.clipping_point = { position = hit:clone() }

        waitForRelease(ui.KeyIndex.S)
        break
      end
    end
    coroutine.yield(nil)
  end

  while true do
    local ray = render.createMouseRay()
    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

      if ui.keyboardButtonPressed(ui.KeyIndex.S) then
        local direction = hit:clone():sub(cursor_data.clipping_point.position):normalize()
        local length = cursor_data.clipping_point.position:distance(cursor_data.selector.position)
        cursor_data.clipping_point.length = length
        cursor_data.clipping_point.direction = direction

        waitForRelease(ui.KeyIndex.S)
        break
      end
    end
    coroutine.yield(nil)
  end

  cursor_data.selector = nil

  track_data['clipping_point_' .. string.format('%03d', clipping_point_number)] = {
    type = 'clipping_point',
    position = cursor_data.clipping_point.position,
    direction = cursor_data.clipping_point.direction,
    length = cursor_data.clipping_point.length
  }

  DataBroker.store("track_data", track_data)
end)

local createZone = (function ()
  local hit = vec3()

  -- Find count of zones
  local zone_count = 0
  for name, _ in pairs(track_data) do
    if string.startsWith(name, "zone_") then
      local no = tonumber(string.gsub(name, "zone_", ""), 10)
      if no > zone_count then zone_count = no end
    end
  end
  local zone_number = zone_count + 1

  cursor_data.selector = { position = hit }

  local outside_points = {}
  local inside_points = {}

  local outside_point_no = 0
  while true do -- Create outside points
    cursor_data.selector.color = rgbm(3, 0, 0, 1)

    local point = nil

    while true do
      local ray = render.createMouseRay()
      if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

        if ui.keyboardButtonPressed(ui.KeyIndex.NumPad0) then
          point = hit:clone()
          waitForRelease(ui.KeyIndex.NumPad0)
          break
        end
      end

      if ui.keyboardButtonPressed(ui.KeyIndex.F) then break end
      coroutine.yield(nil)
    end

    if ui.keyboardButtonPressed(ui.KeyIndex.F) then waitForRelease(ui.KeyIndex.F); break end

    local prev_name = nil
    if outside_point_no ~= 1 then prev_name = "point_" .. string.format('%03d', outside_point_no - 1) end

    outside_point_no = outside_point_no + 1
    outside_points["point_" .. string.format('%03d', outside_point_no)] = {
      position = point,
      prev_name = prev_name,
      number = outside_point_no
    }

    cursor_data.outside_zone_points = outside_points
    coroutine.yield(nil)
  end

  local inside_point_no = 0
  while true do -- Create inside points
    cursor_data.selector.color = rgbm(0, 3, 0, 1)

    local point = nil

    while true do
      local ray = render.createMouseRay()
      if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

        if ui.keyboardButtonPressed(ui.KeyIndex.NumPad0) then
          point = hit:clone()
          waitForRelease(ui.KeyIndex.NumPad0)
          break
        end
      end

      if ui.keyboardButtonPressed(ui.KeyIndex.F) then break end
      coroutine.yield(nil)
    end

    if ui.keyboardButtonPressed(ui.KeyIndex.F) then waitForRelease(ui.KeyIndex.F); break end

    local prev_name = nil
    if inside_point_no ~= 1 then prev_name = "point_" .. string.format('%03d', inside_point_no - 1) end

    inside_point_no = inside_point_no + 1
    inside_points["point_" .. string.format('%03d', inside_point_no)] = {
      position = point,
      prev_name = prev_name,
      number = inside_point_no
    }

    cursor_data.inside_zone_points = inside_points

    if ui.keyboardButtonPressed(ui.KeyIndex.F) then break end
    coroutine.yield(nil)
  end

  cursor_data.selector = nil
  cursor_data.outside_zone_points = nil
  cursor_data.inside_zone_points = nil

  track_data['zone_' .. string.format('%03d', zone_number)] = {
    type = 'zone',
    outside_points = outside_points,
    outside_points_count = outside_point_no,
    inside_points = inside_points,
    inside_points_count = inside_point_no
  }

  DataBroker.store("track_data", track_data)
end)

local createGate = (function (gate_name)
  local hit = vec3()

  cursor_data.selector = { position = hit }
  cursor_data.gate = {}

  while true do
    local ray = render.createMouseRay()
    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

      if ui.keyboardButtonPressed(ui.KeyIndex.S) then
        cursor_data.gate.point_a = hit:clone()

        waitForRelease(ui.KeyIndex.S)
        break
      end
    end
    coroutine.yield(nil)
  end

  while true do
    local ray = render.createMouseRay()
    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then

      if ui.keyboardButtonPressed(ui.KeyIndex.S) then
        cursor_data.gate.point_b = hit:clone()

        waitForRelease(ui.KeyIndex.S)
        break
      end
    end
    coroutine.yield(nil)
  end

  track_data[gate_name] = {
    type = 'gate',
    name = gate_name,
    point_a = cursor_data.gate.point_a,
    point_b = cursor_data.gate.point_b
  }

  cursor_data.selector = nil
  cursor_data.gate = nil

  DataBroker.store("track_data", track_data)
end)


local running_task = nil

function WindowMain()

  ui.pushFont(ui.Font.Title)
  ui.text("Edge points alignment")

  ui.pushFont(ui.Font.Main)

  if ui.checkbox("Show alignment wireframe", cursor_data.show_wireframe) then
    cursor_data.show_wireframe = not cursor_data.show_wireframe
  end

  ui.text("Front")

  local value, changed = ui.slider("##foffset", car_data.front_offset, 0.5, 3, 'Offset: %.2f')
  if changed then
    car_data.front_offset = tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
  end

  local value, changed = ui.slider("##fwidth", car_data.front_span, 0.05, 1.5, 'Span: %.2f')
  if changed then
    car_data.front_span =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
  end

  ui.text("Rear")

  local value, changed = ui.slider("##roffset", car_data.rear_offset, 0.5, 3, 'Offset: %.2f')
  if changed then
    car_data.rear_offset =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
  end

  local value, changed = ui.slider("##rwidth", car_data.rear_span, 0.05, 1.5, 'Span: %.2f')
  if changed then
    car_data.rear_span =  tonumber(string.format("%.3f", value))
    DataBroker.store("car_data", car_data)
  end

  if ui.button("Save car setup") then saveCarSetup() end
  if ui.button("Save track setup") then saveTrackSetup() end
  if ui.button("Load car setup") then loadCarSetup() end
  if ui.button("Load track points") then loadTrackSetup() end

  ui.separator()

  if ui.button("Create clipping point") then
    running_task = coroutine.create(createClippingPoint)
  end

  if ui.button("Create zone") then
    running_task = coroutine.create(createZone)
  end

  if ui.button("Create start line") then
    running_task = coroutine.create(createGate)
    coroutine.resume(running_task, "start_line")
  end

  if ui.button("Create finish line") then
    running_task = coroutine.create(createGate)
    coroutine.resume(running_task, "finish_line")
  end

  if ui.button("Open config directory") then
    os.openInExplorer(user_cfg_path)
  end

  if running_task ~= nil then
    coroutine.resume(running_task)

    if coroutine.status(running_task) == 'dead' then
      running_task = nil
    end
  end

  ac.debug("running_task", running_task)

  ac.debug("cursor_data", json.encode(DataBroker.serialize(cursor_data)))
  DataBroker.store("cursor_data", cursor_data)
end
