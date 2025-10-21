local Element = require("drift-mode.models.Elements.Element")
local Point = require("drift-mode.models.Common.Point.init")
local Handle = require("drift-mode.models.Elements.Position.Handle")

---@class Position : Element
---@field origin Point
---@field direction vec3
local Position = class("Position", Element)
Position.__model_path = "Elements.Position.Position"

---@param origin Point
---@param direction vec3
function Position:initialize(name, origin, direction)
    Element.initialize(self, name)
    self.origin = origin
    self.direction = direction
end

function Position:setEnd(new_end_point)
    self.direction = (new_end_point:value() - self.origin:value()):normalize()
    self:setDirty()
end

function Position:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawCircleFilled(coord_transformer(self.origin), scale * 1, color)
    ui.drawLine(
        coord_transformer(self.origin),
        coord_transformer(Point.Point(self.origin:value() + self.direction * 2)),
        color,
        scale * 0.5
    )
end

---@return { [HandleId] : PositionHandle }
function Position:gatherHandles()
    local handles = {}
    local prefix = self:getId() .. "_"

    handles[prefix .. Handle.Type.Origin] = Handle(
        self.origin,
        self,
        Handle.Type.Origin,
        Point.Drawers.Simple()
    )

    handles[prefix .. Handle.Type.Origin] = Handle(
        Point.Point(self.origin:value() + self.direction),
        self,
        Handle.Type.Ending,
        Point.Drawers.Simple()
    )

    return handles
end

local Assert = require('drift-mode.assert')
local function test()
end
test()

return Position
