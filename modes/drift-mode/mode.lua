local DataBroker = require('drift-mode/databroker')
local json = require('drift-mode/json')

local track_data = nil

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


function script.draw3D()
  drawTrackPOIs()
end