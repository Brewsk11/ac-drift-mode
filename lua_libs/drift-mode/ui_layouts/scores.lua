
function appScoresLayout(run_state_data, game_state, track_data)
    -- ui.beginTransparentWindow('logo', vec2(510, 110), vec2(50, 50), true)
    -- ui.image("logo white.png", vec2(50, 50), true)
    -- ui.endTransparentWindow()

    if not run_state_data or not game_state then return end

    if game_state:isPlaymode() then
      local window_height = 195 + #run_state_data.zoneStates * 16 + #run_state_data.clipStates * 16
      ui.beginChild('scoresWindow', vec2(450, window_height), true)

      ui.drawRectFilled(vec2(0, 0), vec2(450, window_height), rgbm(0.15, 0.15, 0.15, 0.4))

      ui.pushFont(ui.Font.Main)
      ui.text(track_data.name)
      ui.offsetCursorY(-10)
      ui.pushFont(ui.Font.Huge)
      ui.text(string.format("Total score: %.0f", run_state_data.totalScore))
      ui.pushFont(ui.Font.Main)
      ui.offsetCursorY(-10)
      ui.text(string.format("Average run multiplier: %.2f%%", run_state_data.avgMultiplier * 100))

      -- Zones
      ui.offsetCursorY(20)
      local header_orig = ui.getCursor()
      ui.pushFont(ui.Font.Main)
      ui.text("Zone")
      ui.setCursor(header_orig + vec2(150, 0))
      ui.text("Score")
      ui.setCursor(header_orig + vec2(200, 0))
      ui.text("Max")
      ui.setCursor(header_orig + vec2(250, 0))
      ui.text("Perf.")
      ui.setCursor(header_orig + vec2(300, 0))
      ui.text("Dist.")
      ui.setCursor(header_orig + vec2(350, 0))
      ui.text("Done")
      ui.offsetCursorY(10)
      ui.pushFont(ui.Font.Monospace)
      for _, zone_state in ipairs(run_state_data.zoneStates) do
        local zone_orig = ui.getCursor()
        ui.text(zone_state.zone)
        ui.setCursor(zone_orig + vec2(150, 0))
        ui.text(string.format("%.0f", zone_state.score))
        ui.setCursor(zone_orig + vec2(200, 0))
        ui.text(tostring(zone_state.maxPoints))
        ui.setCursor(zone_orig + vec2(250, 0))
        ui.text(string.format("%.2f%%", zone_state.performance * 100))
        ui.setCursor(zone_orig + vec2(300, 0))
        local zone_distance = 0
        if zone_state.active or zone_state.finished then
          zone_distance = zone_state.timeInZone
        end
        ui.text(string.format("%.2f%%", zone_distance * 100))
        ui.setCursor(zone_orig + vec2(350, 0))
        local done = "-"
        if zone_state.finished then done = "X" end
        ui.text(done)
      end

      -- Clips
      ui.offsetCursorY(20)
      local header_orig = ui.getCursor()
      ui.pushFont(ui.Font.Main)
      ui.text("Clip")
      ui.setCursor(header_orig + vec2(150, 0))
      ui.text("Score")
      ui.setCursor(header_orig + vec2(200, 0))
      ui.text("Max")
      ui.setCursor(header_orig + vec2(250, 0))
      ui.text("Perf.")
      ui.setCursor(header_orig + vec2(300, 0))
      ui.text("Frac.")
      ui.setCursor(header_orig + vec2(350, 0))
      ui.text("Done")
      ui.offsetCursorY(10)
      ui.pushFont(ui.Font.Monospace)
      for _, clip_state in ipairs(run_state_data.clipStates) do
        local clip_orig = ui.getCursor()
        ui.text(clip_state.clip)
        ui.setCursor(clip_orig + vec2(150, 0))
        ui.text(string.format("%.0f", clip_state.score))
        ui.setCursor(clip_orig + vec2(200, 0))
        ui.text(tostring(clip_state.maxPoints))
        ui.setCursor(clip_orig + vec2(250, 0))
        ui.text(string.format("%.2f%%", clip_state.performance * 100))
        ui.setCursor(clip_orig + vec2(300, 0))
        ui.text(string.format("%.2f%%", clip_state.hitRatioMult * 100))
        ui.setCursor(clip_orig + vec2(350, 0))
        local done = "-"
        if clip_state.crossed then done = "X" end
        ui.text(done)
      end
      ui.endChild()
    else
      ui.beginChild('helpWindow', vec2(420, 600), true)
      ui.pushFont(ui.Font.Huge)
      ui.text("Help")
      ui.pushFont(ui.Font.Main)
      ui.text("By default the game loads first found user track config,\nand if not exists then first \"official\" track config\n(shipped with the mod)")
      ui.text("To bind a key to restart a drift run bind \"Extra option F\"\nin Content Mananger controls menu.")
      ui.pushFont(ui.Font.Title)
      ui.text("Creating zones:")
      ui.pushFont(ui.Font.Main)
      ui.text("Trace the outside line first, then after confirming\ntrace the inside line IN THE SAME DIRECTION.\nThis is important to correctly calculate scoring.")
      ui.text("S - place point\nQ - undo\nA - cancel\nF - confirm")
      ui.offsetCursorY(30)
      ui.pushFont(ui.Font.Main)
      ui.text("More features and improvements are planned.\nCheck out RaceDepartment and Github pages for updates.")
      ui.text("Thanks for playing!")
      ui.endChild()
    end
end