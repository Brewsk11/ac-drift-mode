local EventSystem = require('drift-mode.EventSystem')
local listener_id = EventSystem:registerListener('app-settings')

local Resources = require('drift-mode.Resources')
local EditorsState = require("drift-mode.models.Editor.EditorsState")


local ControlApp = {}


---@type EditorsState
local editors_state = EditorsState()
EventSystem:emit(EventSystem.Signal.EditorsStateChanged, editors_state)


local EditorTab = require('Settings.tabs.Editor.Editor')
local CarSetupTab = require('Settings.tabs.CarSetup')
local AboutTab = require('Settings.tabs.About')
local DebugTab = require('Settings.tabs.Debug')

local __tabs = {
    { 'Course editor', EditorTab.drawUIEditor },
    { 'Car setup',     CarSetupTab.drawUICarSetup },
    { 'About',         AboutTab.drawUIAbout }
}

local function drawAppUI()
    local logo_height = 150

    ui.image(Resources.EmblemFlat, vec2(ui.availableSpaceX(), logo_height), ui.ImageFit.Fit)

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
end

return ControlApp
