local Drawer = require('drift-mode.models.Drawer')
local DrawerPosition = require('drift-mode.models.Elements.Position.Drawers.Base')

---@class DrawerPositionSetup : DrawerPosition
---@field color rgbm
local DrawerPositionSetup = class("DrawerPositionSetup", DrawerPosition)
DrawerPositionSetup.__model_path = "Elements.Position.Drawers.Setup"

function DrawerPositionSetup:initialize(color)
    DrawerPosition.initialize(self)
    self.color = color or rgbm(2, 0.7, 0.5, 3)
end

---@param startingPoint Position
function DrawerPositionSetup:draw(startingPoint)
    DrawerPosition.draw(self, startingPoint)

    startingPoint.origin:draw(0.6)

    for _, handle in pairs(startingPoint:gatherHandles()) do
        handle:draw()
    end

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

return DrawerPositionSetup
