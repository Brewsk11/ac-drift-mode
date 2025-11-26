local EventSystem = require('drift-mode.EventSystem')
local ConfigIO = require('drift-mode.ConfigIO')

local listener_id = EventSystem:registerListener("apptab-carsetup")

local CameraHelper = require('drift-mode.CameraHelper')
local CarConfig = require("drift-mode.models.Misc.CarConfig")
local CarConfigState = require("drift-mode.models.Misc.CarConfigState")


local CarSetup = {}

---@type EditorsState?
local editors_state = nil

---@type CarConfigState
local car_config_state = CarConfigState()

local function loadCar()
    local car_data = ConfigIO.loadCarConfig()
    if car_data == nil then
        car_data = CarConfig()
    end

    car_config_state.shared_data.front_offset = car_data.frontOffset
    car_config_state.shared_data.front_span = car_data.frontSpan
    car_config_state.shared_data.rear_offset = car_data.rearOffset
    car_config_state.shared_data.rear_span = car_data.rearSpan

    EventSystem:emit(EventSystem.Signal.CarConfigChanged, car_data)
end
loadCar()

local is_helper_cam_active = false
local unsaved_changes = false

function CarSetup.drawUICarSetup()
    EventSystem:listen(listener_id, EventSystem.Signal.EditorsStateChanged, function(payload)
        editors_state = payload
    end)

    if editors_state == nil then
        return
    end

    -- [CHECKBOX] Enable configuration
    if ui.checkbox("Show guides", editors_state.isCarSetup) then
        editors_state.isCarSetup = not editors_state.isCarSetup
        EventSystem:emit(EventSystem.Signal.EditorsStateChanged, editors_state)
    end

    -- [CHECKBOX] Enable helper camera
    ui.sameLine(0, 32)
    if ui.checkbox("Helper camera", is_helper_cam_active) then
        is_helper_cam_active = not is_helper_cam_active
        if is_helper_cam_active then
            CameraHelper.grabCamera("For car alignment")
        else
            CameraHelper.disposeCamera()
        end
    end

    if is_helper_cam_active then
        local car = ac.getCar(0)
        local cam_pos = car.position + vec3(0, 80, 0)

        CameraHelper.setCamera(
            cam_pos,
            vec3.tmp(), -- Any will do because the camera stays on horizon. Will need to figure it out
            vec3(0, -1, 0),
            5
        )
    end

    ui.offsetCursorY(15)

    -- [DECORATIVE] Front
    ui.pushFont(ui.Font.Title)
    ui.text("Front")
    ui.popFont()

    -- [SLIDER] Front offset
    ui.offsetCursor(vec2(65, -35))
    ui.pushFont(ui.Font.Monospace)
    ui.pushItemWidth(ui.availableSpaceX())
    local value, changed = ui.slider("##foffset", car_config_state.shared_data.front_offset, 0.5, 3, 'Offset: %.2f')
    if changed then
        unsaved_changes = true
        car_config_state.shared_data.front_offset = tonumber(string.format("%.3f", value))
    end

    -- [SLIDER] Front span
    ui.offsetCursorX(65)
    local value, changed = ui.slider("##fwidth", car_config_state.shared_data.front_span, 0.05, 1.5, 'Span: %.2f')
    if changed then
        unsaved_changes = true
        car_config_state.shared_data.front_span = tonumber(string.format("%.3f", value))
    end
    ui.popFont()
    ui.popItemWidth()

    -- [DECORATIVE] Front
    ui.offsetCursorY(15)
    ui.pushFont(ui.Font.Title)
    ui.text("Rear")
    ui.popFont()

    -- [SLIDER] Rear offset
    ui.offsetCursor(vec2(65, -35))
    ui.pushFont(ui.Font.Monospace)
    ui.pushItemWidth(ui.availableSpaceX())
    local value, changed = ui.slider("##roffset", car_config_state.shared_data.rear_offset, 0.5, 3, 'Offset: %.2f')
    if changed then
        unsaved_changes = true
        car_config_state.shared_data.rear_offset = tonumber(string.format("%.3f", value))
    end

    -- [SLIDER] Rear span
    ui.offsetCursorX(65)
    local value, changed = ui.slider("##rwidth", car_config_state.shared_data.rear_span, 0.05, 1.5, 'Span: %.2f')
    if changed then
        unsaved_changes = true
        car_config_state.shared_data.rear_span = tonumber(string.format("%.3f", value))
    end
    ui.popFont()
    ui.popItemWidth()

    ui.offsetCursorY(15)

    local button_width = 140
    local button_height = 40
    local button_gap = 12

    local initial_gap = (ui.windowWidth() - (2 * button_width + button_gap)) / 2
    ui.offsetCursorX(initial_gap)

    -- [BUTTON] Save car config
    if ui.button("Save##saveCar", vec2(button_width, button_height)) then
        local car_data = CarConfig(
            car_config_state.shared_data.front_offset,
            car_config_state.shared_data.front_span,
            car_config_state.shared_data.rear_offset,
            car_config_state.shared_data.rear_span
        )

        ConfigIO.saveCarConfig(car_data)
        unsaved_changes = false
        EventSystem:emit(EventSystem.Signal.CarConfigChanged, car_data)
    end

    if unsaved_changes then
        ui.notificationCounter()
    end

    -- [BUTTON] Reset car config
    ui.sameLine(0, button_gap)
    if ui.button("Reset##resetCar", vec2(button_width, button_height)) then
        loadCar()
    end

    -- [BUTTON] Open configuration directory
    ui.offsetCursor(vec2(initial_gap, button_gap))
    if ui.button("Open directory with car setups##openCarDir", vec2(button_width * 2 + button_gap, button_height)) then
        os.openInExplorer(ac.getFolder(ac.FolderID.ExtCfgUser) .. "\\drift-mode\\cars")
    end
end

return CarSetup
