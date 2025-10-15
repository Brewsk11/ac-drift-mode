local Element = require("drift-mode.models.Elements.Element")
local Point = require("drift-mode.models.Common.Point.Point")
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
end

function Position:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawCircleFilled(coord_transformer(self.origin), scale * 1, color)
    ui.drawLine(
        coord_transformer(self.origin),
        coord_transformer(Point(self.origin:value() + self.direction * 2)),
        color,
        scale * 0.5
    )
end

function Position:gatherHandles()
    local handles = {}

    handles[#handles + 1] = Handle(
        self.origin,
        self,
        Handle.Type.Origin
    )

    handles[#handles + 1] = Handle(
        Point(self.origin:value() + self.direction),
        self,
        Handle.Type.Ending
    )

    return handles
end

local Assert = require('drift-mode.assert')
local function test()
end
test()

return Position
