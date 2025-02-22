local Resources = require('drift-mode/Resources')
local Assert = require('drift-mode/Assert')

local ScoresLayout = {}

---@param scoring_objects_states ScoringObjectState[]
local function compactObjectList(scoring_objects_states)
    local entry_height = 18
    local entry_gap = 8

    local column_width = 60
    local min_object_name_width = 100
    local max_columns = 2

    local info_columns_count = math.min(math.floor((ui.windowWidth() - min_object_name_width) / column_width),
        max_columns)

    for _, object_state in ipairs(scoring_objects_states) do
        local icon = nil
        if object_state.isInstanceOf(ZoneState) then
            icon = Resources.IconZoneWhite
        elseif object_state.isInstanceOf(ClipState) then
            icon = Resources.IconClipWhite
        else
            Assert.Error("")
        end

        local color = rgbm(1, 1, 1, 0.15)
        if object_state:isDone() then color = rgbm(1, 1, 1, 0.7) end
        ui.image(icon, vec2(entry_height, entry_height), color)
        ui.sameLine(0, 4)
        ui.textAligned(object_state:getName(), vec2(0, 0),
            vec2(ui.availableSpaceX() - info_columns_count * column_width, entry_height))
        ui.pushFont(ui.Font.Monospace)
        ui.sameLine(0, 0)

        ui.drawRect(ui.getCursor(), ui.getCursor() + vec2(column_width, entry_height), Resources.Colors.FaintBg, 2)
        if object_state:getScore() > 0 then
            ui.drawRectFilled(ui.getCursor(),
                ui.getCursor() + vec2(column_width * object_state:getScore() / object_state:getMaxScore(), entry_height),
                Resources.Colors.FaintBg, 2)
        end

        ui.dwriteTextAligned(string.format("%d", object_state:getScore()), 12, ui.Alignment.Center, ui.Alignment.Center,
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

                formattedLabel("Score", "%d", object_state:getScore())
                formattedLabel("Max score", "%d", object_state:getMaxScore())
                formattedLabel("%", "%.2f%%", object_state:getScore() / object_state:getMaxScore() * 100)
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

            local end_speed = ui.getCursor() + vec2(multiinfo_column_width * object_state:getSpeed(), entry_height / 3)
            local end_angle = ui.getCursor() +
                vec2(multiinfo_column_width * object_state:getAngle(), entry_height / 3 * 2)
            local end_depth = ui.getCursor() + vec2(multiinfo_column_width * object_state:getDepth(), entry_height)

            ui.drawRectFilled(start_speed, end_speed, Resources.Colors.NeutralSpeed, 1)
            ui.drawRectFilled(start_angle, end_angle, Resources.Colors.NeutralAngle, 1)
            ui.drawRectFilled(start_depth, end_depth, Resources.Colors.NeutralRatio, 1)

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

                    formattedLabel("Speed multiplier", object_state:getSpeed())
                    formattedLabel("Angle multiplier", object_state:getAngle())
                    formattedLabel("Depth multiplier", object_state:getDepth())
                    if object_state.isInstanceOf(ZoneState) then
                        ---@cast object_state ZoneState
                        formattedLabel("Distance multiplier", object_state:getTimeInZone() or 0)
                    end
                    ui.text("")
                    if object_state.isInstanceOf(ZoneState) then
                        ---@cast object_state ZoneState
                        formattedLabel("Average multiplier",
                            object_state:getSpeed() * object_state:getAngle() * object_state:getDepth() *
                            (object_state:getTimeInZone() or 1.0))
                        formattedLabel("Final multiplier",
                            object_state:getPerformance() * (object_state:getTimeInZone() or 0))
                    elseif object_state.isInstanceOf(ClipState) then
                        ---@cast object_state ClipState
                        formattedLabel("Final multiplier", object_state:getMultiplier() or 0)
                    end
                    ui.text("")
                    if object_state.isInstanceOf(ZoneState) then
                        ui.text(
                            "Averages may not necessarily produce the final total multiplier as\nthe score is calculated for every point separately, then averaged.")
                        ui.text("Depth means closeness to zone outside line as a ratio of zone width.")
                        ui.text("Distance is the lenght of zone driven through.")
                    elseif object_state.isInstanceOf(ClipState) then
                        ui.text("Depth means closeness to clips origin as a ratio of clips lenght.")
                    end
                end)
            end
        end

        ui.offsetCursorY(entry_gap)
    end
end

---@param scoring_objects_states ScoringObjectState[]
---@param track_data TrackConfig
function ScoresLayout.appScoresLayout(scoring_objects_states, track_data, window_size)
    if not scoring_objects_states or not track_data then return end

    if ui.windowHeight() > 120 then
        -- COURSE NAME
        ui.pushFont(ui.Font.Main)
        ui.image(Resources.LogoWhite, vec2(16, 16))
        ui.sameLine()
        ui.text(track_data.name)
        ui.popFont()

        ui.separator()
    end

    -- TOTAL SCORE
    local total_score_str = ScoringObjectState.aggrScore(scoring_objects_states)
    local max_score_str = ScoringObjectState.aggrMaxScore(scoring_objects_states)
    ui.sameLine(0, 0)
    ui.pushFont(ui.Font.Huge)
    ui.beginGroup()
    ui.beginGroup()
    ui.textAligned(string.format("%d", total_score_str), vec2(1, 0),
        vec2(ui.availableSpaceX(), 60), true)
    ui.popFont()
    ui.endGroup()
    if ui.itemHovered() then
        local tooltip_text = [[Current score: %d
Max score for this course: %d]]
        ui.setTooltip(tooltip_text:format(total_score_str, max_score_str))
    end

    if ui.windowHeight() > 100 then
        -- AVERAGE SCORE

        ui.beginGroup()
        ui.textAligned(string.format("%.2f%%", ScoringObjectState.aggrAvgScore(scoring_objects_states) * 100),
            vec2(1, 0),
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
        compactObjectList(scoring_objects_states)
        ui.endChild()
    end
end

return ScoresLayout
