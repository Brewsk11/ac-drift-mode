function drawModifiers(ranges, drift_state)
  local speedRect = {
    origin = vec2(0, 0),
    size = vec2(300, 25),
    min = ranges.speedRange.start,
    max = ranges.speedRange.finish,
    name = "Speed",
    color = rgbm(230 / 255, 138 / 255, 46 / 255, 1)
  }

  local angleRect = {
    origin = vec2(0, 30),
    size = vec2(300, 25),
    min = ranges.angleRange.start,
    max = ranges.angleRange.finish,
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

  local widgetSize = vec2(350, 163)

  local function drawInfobar(rect, value)
    if value == nil then return end
    rect.origin = rect.origin + vec2(26, 17)

    ui.drawRect(rect.origin, rect.origin + rect.size, rect.color, 2)

    if value ~= nil then
      ui.drawRectFilled(rect.origin, rect.origin + vec2(rect.size.x * value, rect.size.y), rect.color, 2)
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

  local ratio_nil = drift_state.shared_data.ratio_mult
  if drift_state.shared_data.ratio_mult == nil then ratio_nil = 0 end

  ui.beginChild('infobars', widgetSize, true)
  ui.pushDWriteFont("ACRoboto700.ttf")
  ui.drawRectFilled(vec2(10, 2), widgetSize - vec2(10, 2), rgbm(0.3, 0.3, 0.3, 0.5), 10)
  drawInfobar(speedRect, drift_state.shared_data.speed_mult)
  drawInfobar(angleRect, drift_state.shared_data.angle_mult)
  drawInfobar(ratioRect, ratio_nil)
  drawInfobar(compoundRect, drift_state:getFinalMult())
  ui.endChild()
end
