function drawModifiers(min_speed, max_speed, min_angle, max_angle, current_ratio, mult_speed, mult_angle)
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