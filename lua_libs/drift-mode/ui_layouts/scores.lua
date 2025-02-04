local Resources = require('drift-mode/Resources')

---@param run_state_data RunStateData
local function compactObjectList(run_state_data)
    local entry_height = 18
    local entry_gap = 8

    local column_width = 60
    local min_object_name_width = 100
    local max_columns = 2

    local info_columns_count = math.min(math.floor((ui.windowWidth() - min_object_name_width) / column_width),
        max_columns)

    for _, object_state in ipairs(run_state_data.scoringObjectStates) do
        local icon = nil
        if object_state.isInstanceOf(ZoneStateData) then
            icon = Resources.IconZoneWhite
        elseif object_state.isInstanceOf(ClipStateData) then
            icon = Resources.IconClipWhite
        else
            Assert.Error("")
        end

        local color = rgbm(1, 1, 1, 0.15)
        if object_state.done then color = rgbm(1, 1, 1, 0.7) end
        ui.image(icon, vec2(entry_height, entry_height), color)
        ui.sameLine(0, 4)
        ui.textAligned(object_state.name, vec2(0, 0),
            vec2(ui.availableSpaceX() - info_columns_count * column_width, entry_height))
        ui.pushFont(ui.Font.Monospace)
        ui.sameLine(0, 0)

        ui.drawRect(ui.getCursor(), ui.getCursor() + vec2(column_width, entry_height), Resources.ColorFaintBg, 2)
        if object_state.score > 0 then
            ui.drawRectFilled(ui.getCursor(),
                ui.getCursor() + vec2(column_width * object_state.score / object_state.max_score, entry_height),
                Resources.ColorFaintBg, 2)
        end

        ui.dwriteTextAligned(string.format("%d", object_state.score), 12, ui.Alignment.Center, ui.Alignment.Center,
            vec2(column_width, entry_height), false, rgbm(1, 1, 1, 1))
        if ui.itemHovered() then
            ui.tooltip(function()
                local function formattedLabel(label, format, value)
                    ui.pushFont(ui.Font.Main)
                    ui.textAligned(label, vec2(0, 0), vec2(60, 16))
                    ui.sameLine(0, 0)
                    ui.pushFont(ui.Font.Monospace)
                    ui.textAligned(string.format(format, value), vec2(1, 1), vec2(50, 16))
                    ui.popFont()
                    ui.popFont()
                end

                formattedLabel("Score", "%d", object_state.score)
                formattedLabel("Max score", "%d", object_state.max_score)
                formattedLabel("%", "%.2f%%", object_state.score / object_state.max_score * 100)
            end)
        end

        ui.popFont()

        if info_columns_count == 2 then
            ui.sameLine(0, 0)
            ui.offsetCursorX(10)

            local multiinfo_column_width = column_width - 10

            local start_speed = ui.getCursor() + vec2(0, 0)
            local start_angle = ui.getCursor() + vec2(0, entry_height / 3 + 0.5)
            local start_depth = ui.getCursor() + vec2(0, entry_height / 3 * 2 + 0.5)

            local end_speed = ui.getCursor() + vec2(multiinfo_column_width * object_state.speed, entry_height / 3)
            local end_angle = ui.getCursor() + vec2(multiinfo_column_width * object_state.angle, entry_height / 3 * 2)
            local end_depth = ui.getCursor() + vec2(multiinfo_column_width * object_state.depth, entry_height)

            ui.drawRectFilled(start_speed, end_speed, Resources.ColorNeutralSpeed, 1)
            ui.drawRectFilled(start_angle, end_angle, Resources.ColorNeutralAngle, 1)
            ui.drawRectFilled(start_depth, end_depth, Resources.ColorNeutralRatio, 1)

            ui.offsetCursorX(-10)

            ui.beginGroup()
            ui.textAligned(string.format(""), vec2(1, 1), vec2(column_width, entry_height))
            ui.endGroup()
            if ui.itemHovered() then
                ui.tooltip(function()
                    local function formattedLabel(label, value)
                        ui.textAligned(label, vec2(0, 0), vec2(120, 16))
                        ui.sameLine(0, 0)
                        ui.pushFont(ui.Font.Monospace)
                        ui.textAligned(string.format("%.2f%%", value * 100), vec2(1, 1), vec2(50, 16))
                        ui.popFont()
                    end

                    formattedLabel("Speed multiplier", object_state.speed)
                    formattedLabel("Angle multiplier", object_state.angle)
                    formattedLabel("Depth multiplier", object_state.depth)
                    if object_state.isInstanceOf(ZoneStateData) then
                        formattedLabel("Distance multiplier", object_state.timeInZone or 0)
                    end
                    ui.text("")
                    if object_state.isInstanceOf(ZoneStateData) then
                        formattedLabel("Average multiplier",
                            object_state.speed * object_state.angle * object_state.depth *
                            (object_state.timeInZone or 1.0))
                        formattedLabel("Final multiplier", object_state.performance * (object_state.timeInZone or 0))
                    elseif object_state.isInstanceOf(ClipStateData) then
                        formattedLabel("Final multiplier", object_state.multiplier or 0)
                    end
                    ui.text("")
                    if object_state.isInstanceOf(ZoneStateData) then
                        ui.text(
                            "Averages may not necessarily produce the final total multiplier as\nthe score is calculated for every point separately, then averaged.")
                        ui.text("Depth means closeness to zone outside line as a ratio of zone width.")
                        ui.text("Distance is the lenght of zone driven through.")
                    elseif object_state.isInstanceOf(ClipStateData) then
                        ui.text("Depth means closeness to clips origin as a ratio of clips lenght.")
                    end
                end)
            end
        end

        ui.offsetCursorY(entry_gap)
    end
end

---comment
---@param run_state_data RunStateData
---@param track_data TrackConfig
function appScoresLayout(run_state_data, track_data)
    if not run_state_data then return end

    if ui.windowHeight() > 120 then
        -- COURSE NAME
        ui.pushFont(ui.Font.Main)
        ui.image(Resources.LogoWhite, vec2(16, 16))
        ui.sameLine()
        ui.text(track_data.name)
        if ui.itemHovered() then
            ui.setTooltip(string.format("Max course score: %d", run_state_data.maxScore))
        end
        ui.popFont()

        ui.separator()
    end

    -- TOTAL SCORE
    ui.sameLine(0, 0)
    ui.pushFont(ui.Font.Huge)
    ui.beginGroup()
    ui.beginGroup()
    ui.textAligned(string.format("%d", run_state_data.totalScore), vec2(1, 0), vec2(ui.availableSpaceX(), 60), true)
    ui.popFont()
    ui.endGroup()
    if ui.itemHovered() then
        ui.setTooltip("Current score")
    end

    if ui.windowHeight() > 100 then
        -- AVERAGE SCORE
        ui.beginGroup()
        ui.textAligned(string.format("%.2f%%", run_state_data.avgMultiplier * 100), vec2(1, 0),
            vec2(ui.availableSpaceX(), 20), true)
        ui.endGroup()
        if ui.itemHovered() then
            ui.setTooltip("Average score percentage from all zones & clips that have been already scored on.\n\
This is a very good score-independent run quality metric.")
        end
    end
    ui.endGroup()

    if ui.windowHeight() > 160 then
        ui.offsetCursorY(10)
        ui.separator()
        ui.offsetCursorY(10)

        ui.beginChild("scores_app_objects_list_pane", ui.availableSpace(), false,
            ui.WindowFlags.NoScrollbar + ui.WindowFlags.NoBackground)
        compactObjectList(run_state_data)
        ui.endChild()
    end
end
