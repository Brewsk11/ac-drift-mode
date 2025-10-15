local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")


---@class PoisitionHandle : Handle
---@field position Position
local PoisitionHandle = class("PoisitionHandle", Handle)
PoisitionHandle.__model_path = "Elements.Position.Handle"

---@enum PoisitionHandle.Type
PoisitionHandle.Type = {
  Origin = "Origin",
  Ending = "Ending"
}

function PoisitionHandle:initialize(point, position, type)
  Handle.initialize(self, point)
  self.position = position
  self.type = type
end

function PoisitionHandle:set(new_pos)
  if self.type == PoisitionHandle.Type.Origin then
    self.position.origin:set(new_pos)
  elseif self.type == PoisitionHandle.Type.Ending then
    self.position:setEnd(Point(new_pos))
  end
end

return PoisitionHandle
