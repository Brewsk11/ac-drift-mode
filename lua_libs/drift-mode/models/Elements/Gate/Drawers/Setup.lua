local DrawerGate = require('drift-mode.models.Elements.Gate.Drawers.Base')
local DrawerSegmentLine = require("drift-mode.models.Common.Segment.Drawers.Line")

---@class DrawerGateSetup : DrawerGate
---@field drawerSegment DrawerSegment
local DrawerGateSetup = class("DrawerGateSetup", DrawerGate)
DrawerGateSetup.__model_path = "Elements.Gate.Drawers.Setup"

function DrawerGateSetup:initialize(color)
    self.drawerSegment = DrawerSegmentLine(color)
end

---@param gate Gate
function DrawerGateSetup:draw(gate)
    DrawerGate.draw(self, gate)

    if gate.segment == nil then return end

    self.drawerSegment:draw(gate.segment)

    for _, handle in pairs(gate:gatherHandles()) do
        handle:draw()
    end

    render.debugText(gate:getCenter():value() + vec3(0, 0.5, 0), gate.name)
end

return DrawerGateSetup
