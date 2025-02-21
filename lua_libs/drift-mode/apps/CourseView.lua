local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener('app-courseview')

local Resources = require('drift-mode/Resources')
local MinimapHelper = require('drift-mode/MinimapHelper')

require('drift-mode/models')

---@type TrackConfig?
local track_data = nil

---@type CarConfig?
local car_config = nil

---@type ScoringObjectState[]?
local scoring_object_states = nil

local app_map_canvas = ui.ExtraCanvas(vec2(1024, 1024)):clear(rgbm(0, 0, 0, 0)):setName("Testing")
local saving_canvas = ui.ExtraCanvas(vec2(2048, 2048)):clear(rgbm(0, 0, 0, 0)):setName("savingcanvas")

local CourseView = {}

---@type MinimapHelper
local minimap_helper = MinimapHelper(ac.getFolder(ac.FolderID.CurrentTrackLayout), vec2(1024, 1024))

function CourseView.Main(dt)
    EventSystem.listen(listener_id, EventSystem.Signal.TrackConfigChanged, function(payload)
        track_data = payload;
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.CarConfigChanged, function(payload)
        car_config = payload;
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStateChanged, function(payload)
        if scoring_object_states == nil then return end
        for idx, obj in ipairs(scoring_object_states) do
            if obj:getName() == payload.name then
                if obj:updatesFully() then
                    scoring_object_states[idx] = payload.payload
                else
                    obj:consumeUpdate(payload.payload)
                end
                break
            end
        end
    end)
    EventSystem.listen(listener_id, EventSystem.Signal.ScoringObjectStatesReset, function(payload)
        scoring_object_states = payload;
    end)

    local window_size = ui.windowSize()

    app_map_canvas:clear()
    app_map_canvas:update(function(dt)
        if track_data then
            local bounding_box = track_data:getBoundingBox(0)

            minimap_helper:setViewportSize(window_size)
            minimap_helper:setBoundingBox(bounding_box)

            minimap_helper:drawMap(vec2(0, 0))

            minimap_helper:drawTrackConfig(vec2(0, 0), track_data)

            -- minimap_helper:drawBoundingBox(vec2(0, 0))
            minimap_helper:drawCar(vec2(0, 0), 0, car_config)

            minimap_helper:drawRunState(vec2(0, 0), scoring_object_states)
        end
    end)

    ui.drawImage(app_map_canvas, vec2(0, 0), vec2(1024, 1024))
    ui.invisibleButton("button_saving_canvas", ui.windowSize() - vec2(50, 50))

    ui.itemPopup("##courseview_map_contextmenu", function()
        if ui.selectable("Export to PNG") then
            ---@type MinimapHelper
            local saving_mm_helper = MinimapHelper(ac.getFolder(ac.FolderID.CurrentTrackLayout), vec2(2048, 1548))
            saving_mm_helper:setBoundingBox(track_data:getBoundingBox(0))
            saving_canvas:clear()
            saving_canvas:update(function(dt)
                saving_mm_helper:drawMap(vec2(0, 500))
                saving_mm_helper:drawTrackConfig(vec2(0, 500), track_data)
                saving_mm_helper:drawRunState(vec2(0, 500), scoring_object_states)

                local scores = require('drift-mode/ui_layouts/scores_print')
                ui.text(ac.getCarName(0))
                ui.text(os.date())
                scores.appScoresLayout(scoring_object_states, track_data)
            end)

            local file_path = ac.getFolder(ac.FolderID.ExtCfgUser) ..
                "\\drift-mode\\runs\\" ..
                ac.getTrackFullID("__") ..
                "\\" .. track_data.name .. "\\" .. os.date("%Y-%m-%d %H-%M-%S") .. " " .. ac.getCarName(0) .. ".png"
            io.createFileDir(file_path)
            saving_canvas:save(file_path, ac.ImageFormat.PNG)
            ac.setMessage("Saved the run result", file_path)
        end

        if ui.selectable("Open saved runs directory") then
            local directory = ac.getFolder(ac.FolderID.ExtCfgUser) ..
                "\\drift-mode\\runs\\" .. ac.getTrackFullID("__") .. "\\" .. track_data.name
            io.createDir(directory)
            os.openInExplorer(directory)
        end

        -- TODO: Autosave runs
    end)
end

return CourseView
