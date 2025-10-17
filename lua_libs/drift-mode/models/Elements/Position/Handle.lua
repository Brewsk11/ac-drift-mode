local Handle = require("drift-mode.models.Elements.Handle")
local Point = require("drift-mode.models.Common.Point.Point")


---@class PositionHandle : Handle
local PositionHandle = class("PoisitionHandle", Handle)
PositionHandle.__model_path = "Elements.Position.Handle"

---@enum PositionHandle.Type
PositionHandle.Type = {
  Origin = "Origin",
  Ending = "Ending"
}

function PositionHandle:initialize(point, position, type)
  Handle.initialize(self, point, position)
  self.type = type
end

function PositionHandle:set(new_pos)
  local position = self.element
  ---@cast position Position
  if self.type == PositionHandle.Type.Origin then
    position.origin:set(new_pos)
  elseif self.type == PositionHandle.Type.Ending then
    position:setEnd(Point(new_pos))
  end
end

return PositionHandle
