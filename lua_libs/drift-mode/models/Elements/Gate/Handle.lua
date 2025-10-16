local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")


---@class GateHandle : Handle
---@field gate Gate
local GateHandle = class("GateHandle", Handle)
GateHandle.__model_path = "Elements.Gate.Handle"

---@enum GateHandle.Type
GateHandle.Type = {
    Head = "Head",
    Center = "Center",
    Tail = "Tail"
}

function GateHandle:initialize(point, gate, type)
    Handle.initialize(self, point)
    self.gate = gate
    self.type = type
end

function GateHandle:set(new_pos)
    if self.type == GateHandle.Type.Head then
        self.gate.segment:getHead():set(new_pos)
    elseif self.type == GateHandle.Type.Tail then
        self.gate.segment:getTail():set(new_pos)
    elseif self.type == GateHandle.Type.Center then
        self.gate.segment:moveTo(Point(new_pos))
    end
end

return GateHandle
