local EventSystem = require('drift-mode.eventsystem')
local listener_id = EventSystem:registerListener('app-settings')

local Resources = require('drift-mode.Resources')
local EditorsState = require("drift-mode.models.Editor.EditorsState")


local ControlApp = {}


---@type EditorsState
local editors_state = EditorsState()
EventSystem:emit(EventSystem.Signal.EditorsStateChanged, editors_state)


local EditorTab = require('drift-mode.apps.Settings.Tabs.Editor')
local CarSetupTab = require('drift-mode.apps.Settings.Tabs.CarSetup')
local TrackPatcherTab = require('drift-mode.apps.Settings.Tabs.TrackPatcher')
local AboutTab = require('drift-mode.apps.Settings.Tabs.About')
local DebugTab = require('drift-mode.apps.Settings.Tabs.Debug')

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

function ControlApp.Main(dt)
    drawAppUI()

    ac.debug("physics.allowed()", physics.allowed())
end

return ControlApp
