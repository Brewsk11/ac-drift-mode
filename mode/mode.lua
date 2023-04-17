local DataBroker = require('drift-mode/databroker')
local json = require('drift-mode/json')

local track_data = nil
local car_data = nil
local cursor_data = nil

local hiRefreshTimer = 0
local hiTimerDuration = 0.02

local loRefreshTimer = 0
local loTimerDuration = 0.2

function script.update(dt)
  hiRefreshTimer = hiRefreshTimer + dt
  loRefreshTimer = loRefreshTimer + dt

  if loRefreshTimer > loTimerDuration then
    loReloadData()
    loRefreshTimer = 0
  end

  if hiRefreshTimer > hiTimerDuration then
    hiReloadData()
    hiRefreshTimer = 0
  end

  ac.debug("track_data", json.encode(DataBroker.serialize(track_data)))
end

function loReloadData()
  track_data = DataBroker.read("track_data")
end

function hiReloadData()
  car_data = DataBroker.read("car_data")
  cursor_data = DataBroker.read("cursor_data")
end


function drawAligningWireframe()
  local state = ac.getCar(0)

  local rear_center = state.position - state.look * car_data.rear_offset + state.up / 3
  local front_center = state.position + state.look * car_data.front_offset + state.up / 3

  local rear_align_right_center = rear_center + state.side * car_data.rear_span + state.look * 0.15
  local rear_align_left_center =  rear_center - state.side * car_data.rear_span + state.look * 0.15

  local front_align_right_center = front_center + state.side * car_data.front_span
  local front_align_left_center =  front_center - state.side * car_data.front_span

  -- Draw rear alignment planes
  for i = -2, 2, 1 do
    render.debugPlane(rear_center + state.side * i * 0.6, -state.look, rgb(3, 0, 0), 0.6)
  end
  render.debugPlane(rear_align_right_center, state.side, rgb(0, 3, 0), 0.6)
  render.debugPlane(rear_align_left_center, -state.side, rgb(0, 3, 0), 0.6)

  -- Draw front alignment points
  render.debugSphere(front_align_right_center, 0.025)
  render.debugSphere(front_align_left_center, 0.025)
end


function drawTrackPOIs()
  if track_data == nil then
    return
  end

  for name, element in pairs(track_data) do
    if element.type == 'clipping_point' then
      local origin_lifted = element.position + vec3(0, 1, 0)
      render.debugSphere(element.position, 0.02, rgbm(0, 0, 3, 1))
      render.debugLine(element.position, origin_lifted, rgbm(3, 0, 0, 0.2))
      render.debugText(origin_lifted, name)

      if element['direction'] ~= nil then
        render.debugArrow(element.position, element.position + element.direction * element.length, 0.02)
      end
    end


    if element.type == 'zone' then

      local center = vec3(0, 0, 0)

      for _, point in pairs(element.outside_points) do
        center:add(point.position)
        render.debugText(point.position + vec3(0, 0.2, 0), point.number)
        if point.prev_name ~= nil then
          render.debugLine(point.position, element['outside_points'][point.prev_name].position, rgb(3, 0, 0))
        end
      end

      for _, point in pairs(element.inside_points) do
        center:add(point.position)
        render.debugText(point.position + vec3(0, 0.2, 0), point.number)
        if point.prev_name ~= nil then
          render.debugLine(point.position, element['inside_points'][point.prev_name].position, rgb(0, 3, 0))
        end
      end

      center = center / element['outside_points_count'] + element['inside_points_count']
      render.debugText(center + vec3(0, 2, 0), name, rgb.colors.white, 3)
    end

  end
end

function drawCursorPOIs()
  if cursor_data == nil then
    return
  end

  for name, data in pairs(cursor_data) do
    if data == nil then
      goto continue
    end

    if name == 'show_wireframe' and data then drawAligningWireframe() end

    if name == 'selector' then
      render.debugSphere(data.position, 1, data.color)
      render.debugSphere(data.position, 0.02, data.color)
    end

    if name == 'clipping_point' then
      render.debugSphere(data.position, 0.02, rgbm(0, 0, 3, 0.5))

      if data['direction'] == nil then
        render.debugArrow(data.position, cursor_data.selector.position, 0.02)
      end
    end

    if name == 'outside_zone_points' then
      for _, point_data in pairs(data) do
        render.debugSphere(point_data.position, 0.02, rgbm(3, 0, 0, 1))
        render.debugText(point_data.position + vec3(0, 0.2, 0), point_data.number)
        if point_data.prev_name ~= nil then
          render.debugLine(point_data.position, data[point_data.prev_name].position, rgbm(3, 0, 0, 1))
        end
      end
    end

    if name == 'inside_zone_points' then
      for _, point_data in pairs(data) do
        render.debugSphere(point_data.position, 0.02, rgbm(0, 3, 0, 1))
        render.debugText(point_data.position + vec3(0, 0.2, 0), point_data.number)
        if point_data.prev_name ~= nil then
          render.debugLine(point_data.position, data[point_data.prev_name].position, rgbm(0, 3, 0, 1))
        end
      end
    end

    ::continue::
  end
end

function script.draw3D()
  drawTrackPOIs()
  drawCursorPOIs()
end