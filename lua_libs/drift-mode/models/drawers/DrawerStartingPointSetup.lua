local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Drawer = require('drift-mode/models/Drawers/Drawer')
local DrawerStartingPoint = require('drift-mode/models/Drawers/DrawerStartingPoint')

---@class DrawerStartingPointSetup : DrawerStartingPoint
---@field color rgbm
local DrawerStartingPointSetup = class("DrawerStartingPointSetup", Drawer)
DrawerStartingPointSetup.__model_path = "Drawers.DrawerStartingPointSetup"

function DrawerStartingPointSetup:initialize(color)
    DrawerStartingPoint.initialize(self)
    self.color = color or rgbm(2, 0.7, 0.5, 3)
end

---@param startingPoint StartingPoint
function DrawerStartingPointSetup:draw(startingPoint)
    DrawerStartingPoint.draw(self, startingPoint)

    startingPoint.origin:draw(0.6)

    render.debugArrow(
        startingPoint.origin:value(),
        startingPoint.origin:value() + startingPoint.direction,
        0.1,
        self.color)

    render.debugLine(
        startingPoint.origin:value(),
        startingPoint.origin:value() + vec3(0, 0.2, 0),
        self.color)

    render.debugText(
        startingPoint.origin:value() + vec3(0, 0.3, 0),
        "Starting point")
end

return DrawerStartingPointSetup
