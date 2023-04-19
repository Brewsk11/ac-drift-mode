local DataBroker = require('drift-mode/databroker')
local json = require('drift-mode/json')

local track_data = nil
local car_data = nil


local hiTimerDuration = 0.1
local hiRefreshTimer = 99 -- Force refresh on 1st frame

local loTimerDuration = 1
local loRefreshTimer = 99 -- Force refresh on 1st frame

local in_zone = false
local zone_active = nil

local cross_line = nil

local current_scoring = nil
local current_ratio = nil
local current_angle = nil
local current_speed = nil
local mult_angle = nil
local mult_speed = nil

local total_score = 0

local zones_data = {}
function calcZones()
  for name, data in pairs(track_data) do
    if data.type == 'zone' then
      zones_data[name] = {
        polygon = zoneToPolygon(data)
      }
    end
  end
end

function zoneToPolygon(zone_data)
  local point_no = 0

  local polygon = {}
  local polygon_2d = {}
  local polygon_projected = {}

  local outside_points = {}
  local outside_points_2d = {}
  local outside_points_projected = {}

  for i = 1, zone_data.outside_points_count do
    point_no = point_no + 1
    local point = zone_data.outside_points['point_' .. string.format('%03d', i)].position
    local point_2d = vec2(point.x, point.z)
    local point_projected = vec3(point.x, 0, point.z)

    polygon[point_no] = point
    polygon_2d[point_no] = point_2d
    polygon_projected[point_no] = point_projected
    outside_points[i] = point
    outside_points_2d[i] = point_2d
    outside_points_projected[i] = point_projected
  end

  local inside_points = {}
  local inside_points_2d = {}
  local inside_points_projected = {}
  for i = zone_data.inside_points_count, 1, -1 do
    point_no = point_no + 1
    local point = zone_data.inside_points['point_' .. string.format('%03d', i)].position
    local point_2d = vec2(point.x, point.z)
    local point_projected = vec3(point.x, 0, point.z)

    polygon[point_no] = point
    polygon_2d[point_no] = point_2d
    polygon_projected[point_no] = point_projected
    inside_points[i] = point
    inside_points_2d[i] = point_2d
    inside_points_projected[i] = point_projected
  end

  return {
    points = polygon,
    points_2d = polygon_2d,
    points_projected = polygon_projected,
    outside_points = outside_points,
    outside_points_2d = outside_points_2d,
    outside_points_projected = outside_points_projected,
    inside_points = inside_points,
    inside_points_2d = inside_points_2d,
    inside_points_projected = inside_points_projected,
  }
end

function segmentIter(points, closed)
  local segments = {}

  if closed == nil then closed = true end

  for i = 1, #points do
    local segment = {}
    if i ~= #points then
      segment.a = points[i]
      segment.b = points[i + 1]
      segments[i] = segment
    elseif closed then
      segment.a = points[i]
      segment.b = points[1]
      segments[i] = segment
    end
  end

  local i = 0
  return function()
    i = i + 1
    return segments[i]
  end
end

function drawPolygon(polygon_data, color)
  for segment in segmentIter(polygon_data) do
    render.debugArrow(segment.a, segment.b, 0.02, color)
  end
end

local function checkIfInPolygon(point, polygon)
  local origin = vec2(0, 0)

  local hits = {}
  local hit_no = 0
  for segment in segmentIter(polygon) do
    local hit = vec2.intersect(origin, point, segment.a, segment.b)

    if hit then
      hit_no = hit_no + 1
      hits[hit_no] = hit
    end
  end

  if #hits % 2 == 1 then return true else return false end
end

function scorePlayer()
  local car = ac.getCar(0)
  local car_direction = car.velocity:clone():normalize()

  current_angle = math.deg(math.acos(car_direction:dot(car.look)))
  current_speed = car.speedKmh

  local max_angle = 80
  local min_angle = 10

  local max_speed = 100
  local min_speed = 30

  local scoring_angle = math.clamp(current_angle, min_angle, max_angle)
  local scoring_speed = math.clamp(current_speed, min_speed, max_speed)

  mult_angle = (scoring_angle - min_angle) / max_angle
  mult_speed = (scoring_speed - min_speed) / (max_speed - min_speed)

  if current_ratio ~= nil then
    current_scoring = current_ratio * mult_angle * mult_speed
    total_score = total_score + current_scoring
  else
    current_scoring = nil
  end
end

function loReloadData()
  track_data = DataBroker.read("track_data")
  calcZones()

  car_data = DataBroker.read("car_data")
end

function hiReloadData()
  scorePlayer()
end

function drawTrackPOIs()
  if track_data == nil then
    return
  end

  for name, element in pairs(track_data) do

    if element.type == 'clipping_point' then
        local origin_lifted = element.position + vec3(0, 3, 0)
        render.debugSphere(element.position, 0.02, rgbm(0, 1, 0, 1))
        render.debugLine(element.position, origin_lifted, rgbm(1, 0, 0, 1))
        render.debugArrow(element.position, element.position + element.direction * element.length, 0.02, rgbm(0, 2, 0, 1))
        render.debugText(origin_lifted, name)
    end


    if element.type == 'zone' then

      local gate_position = nil

      for _, point in pairs(element.outside_points) do
        if point.prev_name ~= nil then
            render.debugLine(point.position, element['outside_points'][point.prev_name].position, rgbm(2, 0, 0, 1))
        else -- First point
            gate_position = point.position
        end
      end

      for _, point in pairs(element.inside_points) do
        if point.prev_name ~= nil then
            render.debugLine(point.position, element['inside_points'][point.prev_name].position, rgbm(0, 2, 0, 1))
        else
            gate_position = gate_position + point.position
        end
      end

      gate_position = gate_position / 2
      render.debugText(gate_position + vec3(0, 3, 0), name)
    end

    if element.type == 'gate' then
      render.debugSphere(element.point_a, 0.02, rgbm(0, 3, 0, 1))
      render.debugSphere(element.point_b, 0.02, rgbm(0, 3, 0, 1))
      render.debugLine(element.point_a, element.point_b, rgbm(0, 3, 0, 1))

      local center = (element.point_a + element.point_b) / 2
      render.debugText(center + vec3(0, 3, 0), element.name)
    end

  end
end

function drawZones()
  for name, data in pairs(zones_data) do
    local color = rgbm(0, 0, 3, 1)
    if zone_active ~= nil and zone_active == name then
      color = rgbm(0, 3, 0, 1)
    end

    drawPolygon(data.polygon.points, color)
    drawPolygon(data.polygon.points_projected, rgbm(3, 0, 0, 1))
  end
end

function rotateVec2(v, theta)
  local new_x = v.x * math.cos(theta) - v.y * math.sin(theta)
  local new_y = v.x * math.sin(theta) + v.y * math.cos(theta)

  return vec2(new_x, new_y)
end

function shortestCrossSection(point, polygon)
  local direction_candidates = {}
  local ray_count = 180

  for i = 1, ray_count do
    direction_candidates[i] = rotateVec2(vec2(0, 100), math.pi / ray_count * i)
  end

  local shortest = nil
  for i = 1, ray_count do
    local dir = direction_candidates[i]

    local outside_hits = {}
    for segment in segmentIter(polygon.outside_points_2d, false) do
      local segment_hit = vec2.intersect(point + dir, point - dir, segment.a, segment.b)
      if segment_hit ~= nil then outside_hits[#outside_hits+1] = segment_hit end
    end

    local inside_hits = {}
    for segment in segmentIter(polygon.inside_points_2d, false) do
      local segment_hit = vec2.intersect(point + dir, point - dir, segment.a, segment.b)
      if segment_hit ~= nil then inside_hits[#inside_hits+1] = segment_hit end
    end

    if #outside_hits ~= 0 and #inside_hits ~= 0 then
      if shortest == nil then shortest = { outside_hit = outside_hits[1], inside_hit = inside_hits[1] }
      else
        local shortest_lenght = shortest.outside_hit:distance(shortest.inside_hit)
        local new_lenght = outside_hits[1]:distance(inside_hits[1])

        if shortest_lenght > new_lenght then
          shortest = { outside_hit = outside_hits[1], inside_hit = inside_hits[1] }
        end
      end
    end
  end

  return shortest
end

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

  local car = ac.getCar(0)
  local car_pos = car.position + (-car.look * car_data.rear_offset)
  local car_pos_2d = vec2(car_pos.x, car_pos.z)

  local zone_active_found = nil
  local in_zone_found = false

  for name, data in pairs(zones_data) do
    if checkIfInPolygon(car_pos_2d, data.polygon.points_2d) then
      in_zone_found = true
      zone_active_found = name
    end
  end

  ac.debug("in_zone_found", in_zone_found)
  ac.debug("zone_active_found", zone_active_found)
  in_zone = in_zone_found
  zone_active = zone_active_found

  local car = ac.getCar(0)
  local rear_pos = car.position + (-car.look * car_data.rear_offset)

  if zone_active then
    cross_line = shortestCrossSection(vec2(rear_pos.x, rear_pos.z), zones_data[zone_active].polygon)
    if cross_line then
      ac.debug("outside", cross_line.outside_hit)
      ac.debug("inside", cross_line.inside_hit)
    end
  else
    cross_line = nil
  end
end

function script.draw3D()
  drawTrackPOIs()
  --drawZones()

  if car_data ~= nil then
    local car = ac.getCar(0)
    local rear_pos = car.position + (-car.look * car_data.rear_offset)
    local rear_pos_proj = vec3(rear_pos.x, 0, rear_pos.z)

    if in_zone and cross_line then
      local shortest_proj = {
        outside_hit = vec3(cross_line.outside_hit.x, 0, cross_line.outside_hit.y),
        inside_hit = vec3(cross_line.inside_hit.x, 0, cross_line.inside_hit.y)
      }
      render.debugLine(shortest_proj.inside_hit, rear_pos_proj, rgbm(0, 3, 0, 1))
      render.debugLine(rear_pos_proj, shortest_proj.outside_hit)

      local cross_distance = shortest_proj.inside_hit:distance(shortest_proj.outside_hit)
      local point_distance = shortest_proj.inside_hit:distance(rear_pos_proj)
      local score = point_distance / cross_distance * 100

      current_ratio = score

      ac.debug("cross", cross_distance)
      ac.debug("point", point_distance)
      ac.debug("score", point_distance / cross_distance * 100)

      render.debugSphere(rear_pos, 0.1, rgbm(0, 3, 0, 1))
      render.debugSphere(rear_pos_proj, 0.1, rgbm(0, 3, 0, 1))
    else
      current_ratio = nil
      render.debugSphere(rear_pos, 0.1, rgbm(3, 0, 0, 1))
      render.debugSphere(rear_pos_proj, 0.1, rgbm(3, 0, 0, 0.3))
    end
  end
end

function script.drawUI()
  local br = vec2(0, 60)
  local ibr = vec2(0, 15)
  local orig = vec2(0, 0)

  ui.beginTransparentWindow('driverStopwatch', vec2(150, 100), vec2(600, 300))
  ui.pushFont(ui.Font.Huge)
  ui.drawText(string.format("Total score: %.0f", total_score), orig, rgbm(1, 1, 1, 1))
  ui.pushFont(ui.Font.Italic)
  ui.drawText(string.format('Angle multiplier: %.2f', mult_angle), orig:add(br), rgbm(1, 1, 1, 1))
  ui.drawText(string.format('Speed multiplier: %.2f', mult_speed), orig:add(ibr), rgbm(1, 1, 1, 1))
  if current_ratio ~= nil then
    ui.drawText(string.format('Zone ratio: %.1f', current_ratio), orig:add(ibr), rgbm(1, 3, 1, 1))
    ui.pushFont(ui.Font.Title)
    ui.drawText(string.format('Currently scoring: %.2f', current_scoring), orig:add(ibr), rgbm(1, 3, 1, 1))
  end
  ui.endTransparentWindow()
end
