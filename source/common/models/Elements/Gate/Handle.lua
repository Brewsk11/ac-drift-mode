local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")


---@class GateHandle : Handle
local GateHandle = class("GateHandle", Handle)
GateHandle.__model_path = "Elements.Gate.Handle"

---@enum GateHandle.Type
GateHandle.Type = {
    Head = "Head",
    Center = "Center",
    Tail = "Tail"
}

function GateHandle:initialize(id, point, gate, type, drawer)
    Handle.initialize(self, id, point, gate, drawer)
    self.type = type
end

---@param new_pos vec3
function GateHandle:set(new_pos)
    local gate = self.element
    ---@cast gate Gate
    if self.type == GateHandle.Type.Head then
        gate.segment:getHead():set(new_pos)
    elseif self.type == GateHandle.Type.Tail then
        gate.segment:getTail():set(new_pos)
    elseif self.type == GateHandle.Type.Center then
        gate.segment:moveTo(Point(new_pos))
    end
end

return GateHandle
