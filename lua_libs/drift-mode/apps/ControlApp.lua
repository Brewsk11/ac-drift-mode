local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
local RaycastUtils = require('drift-mode/RaycastUtils')
local ConfigIO = require('drift-mode/configio')
local Timer = require('drift-mode/timer')
local PP = require('drift-mode/physicspatcher')
local S = require('drift-mode/serializer')
local CourseEditor = require('drift-mode/courseeditor')
local Resources = require('drift-mode/Resources')

local ControlApp = {}

require('drift-mode/models')

local config_list = ConfigIO.listTrackConfigs()

local listener_id = EventSystem.registerListener('app-control')

---@type GameState
local game_state = GameState()

---@type CarConfig?
local car_data = nil

---@type TrackConfigInfo?
local track_config_info = nil

---@type TrackConfig?
local track_data = nil

local function loadCar()
    car_data = ConfigIO.loadCarConfig()
    if car_data == nil then car_data = CarConfig() end
    EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
end
loadCar()

---@param track_cfg_info TrackConfigInfo
local function loadTrack(track_cfg_info)
    track_config_info = track_cfg_info
    track_data = track_config_info:load()
    EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)
end

track_config_info = ConfigIO.getLastUsedTrackConfigInfo()
if track_config_info then
    loadTrack(track_config_info)
elseif #config_list > 0 then
    loadTrack(config_list[1])
else
    track_data = TrackConfig()
end
DataBroker.store("track_data", track_data)

---@type Cursor
local cursor_data = Cursor()
DataBroker.store("cursor_data", cursor_data)

local function teleportToStart()
    if physics.allowed() and track_data and track_data.startingPoint then
        physics.setCarPosition(
            0,
            track_data.startingPoint.origin:value(),
            track_data.startingPoint.direction * -1
        )
    else
        physics.teleportCarTo(0, ac.SpawnSet.HotlapStart)
    end
end

local collider_body = nil

local noPhysicsInfo = false

local function reactivateColliders()
    if not physics.allowed() then
        if not noPhysicsInfo then
            ac.setMessage(
                "Extended physics unavailable",
                "Colliders or teleportation won't work. Consider patching the track from the control panel."
            )
            noPhysicsInfo = true
        end
        return
    end

    --Needs to be in the application code as mode scripts do not allow creating RigidBody objects
    --Moreover, these would be hard to serialize, so the app script asks TrackConfig to list all
    --needed colliders, and the app scripts spawns and disposes of them.
    if collider_body then
        collider_body:setInWorld(false):dispose()
    end
    local colliders = track_data:gatherColliders()
    collider_body = physics.RigidBody(colliders, 1):setSemiDynamic(true, false)
end

local function listenForData()
    local changed = false
    EventSystem.startGroup()
    changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CursorChanged,
        function(payload) cursor_data = payload end) or changed
    changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TrackConfigChanged,
        function(payload)
            track_data = payload; reactivateColliders()
        end) or changed
    changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.TeleportToStart,
        function(payload) teleportToStart() end) or changed
    EventSystem.endGroup(changed)
end

local function refreshRunState()
    ---@type RunStateData
    run_state_data = DataBroker.read("run_state_data")
end

local running_task = nil
local is_helper_cam_active = false
local helper_cam = nil

local timers = {
    listeners = Timer(0.5, listenForData),
    run_state_refresher = Timer(0.05, refreshRunState)
}

---@diagnostic disable-next-line: duplicate-set-field
function script.update(dt)
    for _, timer in pairs(timers) do
        timer:tick(dt)
    end

    if running_task ~= nil then
        coroutine.resume(running_task)
        if coroutine.status(running_task) == 'dead' then
            running_task = nil
        end
    end

    ac.debug("physics.allowed()", physics.allowed())

    if ac.getCar(0).extraF then
        ac.setExtraSwitch(5, false)
        EventSystem.emit(EventSystem.Signal.TeleportToStart, {})
    end

    if helper_cam then
        local car = ac.getCar(0)
        local cam_pos = car.position + vec3(0, 80, 0)
        helper_cam.transform.position:set(cam_pos)
        helper_cam.transform.side:set(car.side)
        helper_cam.transform.look:set(vec3(0, -1, 0))
        helper_cam.fov = 5
    end
end

local function gameStateUpdate()
    DataBroker.store("game_state", game_state)
    EventSystem.emit(EventSystem.Signal.GameStateChanged, game_state)
end

local course_editor = CourseEditor()
local course_editor_enabled = false

local function drawUIEditor()
    if ui.checkbox("Enable course editor", course_editor_enabled) then
        course_editor_enabled = not course_editor_enabled
        game_state.isTrackSetup = course_editor_enabled
        EventSystem.emit("GameStateChanged", game_state)
    end

    if course_editor_enabled then
        course_editor:drawUI()
        course_editor:runEditor()
    end
end


local function drawUICarSetup()
    -- [CHECKBOX] Enable configuration
    if ui.checkbox("Show guides", game_state.isCarSetup) then
        game_state.isCarSetup = not game_state.isCarSetup
        gameStateUpdate()
    end

    -- [CHECKBOX] Enable helper camera
    ui.sameLine(0, 32)
    if ui.checkbox("Helper camera", is_helper_cam_active) then
        is_helper_cam_active = not is_helper_cam_active
        if is_helper_cam_active then
            helper_cam = ac.grabCamera("For car alignment")
        else
            helper_cam:dispose(); helper_cam = nil
        end
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
    local value, changed = ui.slider("##foffset", car_data.frontOffset, 0.5, 3, 'Offset: %.2f')
    if changed then
        car_data.frontOffset = tonumber(string.format("%.3f", value))
        DataBroker.store("car_data", car_data)
        EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
    end

    -- [SLIDER] Front span
    ui.offsetCursorX(65)
    local value, changed = ui.slider("##fwidth", car_data.frontSpan, 0.05, 1.5, 'Span: %.2f')
    if changed then
        car_data.frontSpan = tonumber(string.format("%.3f", value))
        DataBroker.store("car_data", car_data)
        EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
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
    local value, changed = ui.slider("##roffset", car_data.rearOffset, 0.5, 3, 'Offset: %.2f')
    if changed then
        car_data.rearOffset = tonumber(string.format("%.3f", value))
        DataBroker.store("car_data", car_data)
        EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
    end

    -- [SLIDER] Rear span
    ui.offsetCursorX(65)
    local value, changed = ui.slider("##rwidth", car_data.rearSpan, 0.05, 1.5, 'Span: %.2f')
    if changed then
        car_data.rearSpan = tonumber(string.format("%.3f", value))
        DataBroker.store("car_data", car_data)
        EventSystem.emit(EventSystem.Signal.CarConfigChanged, car_data)
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
    if ui.button("Save ##saveCar", vec2(button_width, button_height)) then
        ConfigIO.saveCarConfig(car_data)
    end

    -- [BUTTON] Reset car config
    ui.sameLine(0, button_gap)
    if ui.button("Reset ##resetCar", vec2(button_width, button_height)) then
        loadCar()
    end

    -- [BUTTON] Open configuration directory
    ui.offsetCursor(vec2(initial_gap, button_gap))
    if ui.button("Open directory with car setups##openCarDir", vec2(button_width * 2 + button_gap, button_height)) then
        os.openInExplorer(ac.getFolder(ac.FolderID.ExtCfgUser) .. "\\drift-mode\\cars")
    end
end

local function drawUITrackPatcher()
    -- [BUTTON] Track patch button
    local patch_button_label = "Patch track"
    if PP.isPatched() then patch_button_label = "Unpatch track" end
    if ui.button(patch_button_label, vec2(ui.availableSpaceX(), 60)) then
        if PP.isPatched() then
            PP.restore()
            ac.setMessage("Removed track patch successfully", "")
        else
            PP.patch()
            ac.setMessage("Track patched successfully", "Please restart the game to enable extended physics.")
        end
    end
    ui.offsetCursorY(8)

    local patch_button_label = "Show file to patch"
    if ui.button(patch_button_label, vec2(ui.availableSpaceX(), 30)) then
        os.showInExplorer(PP.getSurfacesPath())
    end
    ui.offsetCursorY(15)

    -- [DECORATIVE] Track patching help text
    local help_text = [[
Functionality requiring patched track:
  - teleportation
  - zone collision

After patching the track restart the game.

Patched tracks may prevent joining online servers, as the local track version would be different than the one on the server.

Patcher modifies surfaces.ini file to enable extended physics.

More information on extended track physics in:]]
    ui.dwriteTextAligned(help_text, 14, -1, -1, vec2(ui.availableSpaceX(), 0), true)

    if ui.textHyperlink("CSP SDK documentation") then
        os.openURL("https://github.com/ac-custom-shaders-patch/acc-lua-sdk/blob/main/common/ac_physics.lua#L7")
    end
end

local function drawUIAbout()
    ui.text("Visit project pages:")
    if ui.textHyperlink("RaceDepartment") then
        os.openURL("https://www.racedepartment.com/downloads/driftmode-competition-drift-gamemode.59863/")
    end
    if ui.textHyperlink("YouTube") then
        os.openURL("https://www.youtube.com/channel/UCzdi8sI1KxO7VXNlo_WaSAA")
    end
    if ui.textHyperlink("GitHub") then
        os.openURL("https://github.com/Brewsk11/ac-drift-mode")
    end
end

local __tabs = {
    { 'Course editor', drawUIEditor },
    { 'Car setup',     drawUICarSetup },
    { 'Track patcher', drawUITrackPatcher },
    { 'About',         drawUIAbout }
}

local function drawAppUI()
    local logo_height = 150

    -- 0.1.79 compatibility
    if ac.getPatchVersionCode() <= 2144 then
        ui.image(Resources.EmblemFlat, vec2(ui.availableSpaceX(), logo_height), true)
    else
        ui.image(Resources.EmblemFlat, vec2(ui.availableSpaceX(), logo_height), ui.ImageFit.Fit)
    end

    ui.tabBar('tabs', function()
        for _, v in ipairs(__tabs) do
            ui.tabItem(v[1], ui.TabItemFlags.None, function()
                ui.childWindow('#scrollMainTabs', ui.availableSpace(), function()
                    ui.offsetCursorY(15)
                    ui.pushItemWidth(ui.availableSpaceX())
                    v[2]()
                    ui.popItemWidth()
                end)
            end)
        end
    end)
end

function ControlApp.Main()
    drawAppUI()
end

gameStateUpdate()
EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

return ControlApp
