local DrawerGate = require('drift-mode.models.Elements.Gate.Drawers.Base')
local DrawerSegmentLine = require("drift-mode.models.Common.Segment.Drawers.Line")


---@class DrawerGateSimple : DrawerGate
---@field drawerSegment DrawerSegment
local DrawerGateSimple = class("DrawerGateSimple", DrawerGate)
DrawerGateSimple.__model_path = "Elements.Gate.Drawers.Simple"

function DrawerGateSimple:initialize(color)
    self.drawerSegment = DrawerSegmentLine(color)
end

---@param gate Gate
function DrawerGateSimple:draw(gate)
    DrawerGate.draw(self, gate)
    if gate.segment then
        self.drawerSegment:draw(gate.segment)
    end
end

return DrawerGateSimple
