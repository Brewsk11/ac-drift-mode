local Resources = require('drift-mode.Resources')
local Assert = require('drift-mode.Assert')

local ZoneState = require("drift-mode.models.Elements.Scorables.Zone.ZoneState")
local ClipState = require("drift-mode.models.Elements.Scorables.Clip.ClipState")

-- TODO: This file should be temporary, merge with scores.lua in the future

local ScoresPrint = {}

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
            vec2(600 - info_columns_count * column_width, entry_height))
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
                    ui.textAligned(label, vec2(0, 0), vec2(60, 16))
                    ui.sameLine(0, 0)
                    ui.textAligned(string.format(format, value), vec2(1, 1), vec2(50, 16))
                end

                formattedLabel("Score", "%d", object_state:getScore())
                formattedLabel("Max score", "%d", object_state:getMaxScore())
                formattedLabel("%", "%.2f%%", object_state:getScore() / object_state:getMaxScore() * 100)
            end)
        end

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
                        ui.textAligned(string.format("%.2f%%", value * 100), vec2(1, 1), vec2(50, 16))
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

---@param scoring_objects_state_data ScoringObjectState[]
---@param track_data TrackConfig
function ScoresPrint.appScoresLayout(scoring_objects_state_data, track_data)
    if not scoring_objects_state_data or not track_data then return end

    local function getMaxScore() -- TODO: CACHE
        local score = 0
        for _, scoring_object in ipairs(scoring_objects_state_data) do
            score = score + scoring_object:getMaxScore()
        end
        return score
    end

    if ui.windowHeight() > 120 then
        -- COURSE NAME
        ui.image(Resources.LogoWhite, vec2(16, 16))
        ui.sameLine()
        ui.text(track_data.name)
        if ui.itemHovered() then
            ui.setTooltip(string.format("Max course score: %d", getMaxScore()))
        end

        ui.separator()
    end

    -- TOTAL SCORE
    local function getScore() -- TODO: CACHE
        local score = 0
        for _, scoring_object in ipairs(scoring_objects_state_data) do
            score = score + scoring_object:getScore()
        end
        return score
    end

    ui.sameLine(0, 0)
    ui.beginGroup()
    ui.beginGroup()
    ui.textAligned(string.format("%d", getScore()), vec2(1, 0), vec2(600, 60), true)
    ui.endGroup()
    if ui.itemHovered() then
        ui.setTooltip("Current score")
    end

    if ui.windowHeight() > 100 then
        -- AVERAGE SCORE

        local function getAvgMultiplier() -- TODO: CACHE
            local mult = 0
            local scoring_finished = 0
            for _, scoring_object_state in ipairs(scoring_objects_state_data) do
                if scoring_object_state:isDone() and scoring_object_state:getMultiplier() ~= nil then
                    mult = mult + scoring_object_state:getMultiplier()
                    scoring_finished = scoring_finished + 1
                end
            end
            if scoring_finished == 0 then return 0 end
            mult = mult / scoring_finished
            return mult
        end

        ui.beginGroup()
        ui.textAligned(string.format("%.2f%%", getAvgMultiplier() * 100), vec2(1, 0),
            vec2(600, 20), true)
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
        compactObjectList(scoring_objects_state_data)
        ui.endChild()
    end
end

return ScoresPrint
