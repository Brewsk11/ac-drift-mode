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

---@type EditorsState
local editors_state = EditorsState()
EventSystem.emit(EventSystem.Signal.EditorsStateChanged, editors_state)

---@type TrackConfigInfo?
local track_config_info = nil

---@type TrackConfig?
local track_data = nil


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


local function listenForData()
    local changed = false
    EventSystem.startGroup()
    changed = EventSystem.listenInGroup(listener_id, EventSystem.Signal.CursorChanged,
        function(payload) cursor_data = payload end) or changed
    EventSystem.endGroup(changed)
end

local running_task = nil

local timers = {
    listeners = Timer(0.5, listenForData)
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
end

local EditorTab = require('drift-mode/apps/ControlAppTabs/Editor')
local CarSetupTab = require('drift-mode/apps/ControlAppTabs/CarSetup')
local TrackPatcherTab = require('drift-mode/apps/ControlAppTabs/TrackPatcher')
local AboutTab = require('drift-mode/apps/ControlAppTabs/About')

local __tabs = {
    { 'Course editor', EditorTab.drawUIEditor },
    { 'Car setup',     CarSetupTab.drawUICarSetup },
    { 'Track patcher', TrackPatcherTab.drawUITrackPatcher },
    { 'About',         AboutTab.drawUIAbout }
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

EventSystem.emit(EventSystem.Signal.TrackConfigChanged, track_data)

return ControlApp
