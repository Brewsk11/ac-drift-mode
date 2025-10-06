local ModelBase = require("drift-mode.models.ModelBase")
local Point = require("drift-mode.models.Common.Point.Point")

---@class StartingPoint : ClassBase
---@field origin Point
---@field direction vec3
local StartingPoint = class("StartingPoint", ModelBase)
StartingPoint.__model_path = "Elements.Position.StartingPoint"

---@param origin Point
---@param direction vec3
function StartingPoint:initialize(origin, direction)
    self.origin = origin
    self.direction = direction
end

function StartingPoint:setEnd(new_end_point)
    self.direction = (new_end_point:value() - self.origin:value()):normalize()
end

function StartingPoint:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawCircleFilled(coord_transformer(self.origin), scale * 1, color)
    ui.drawLine(
        coord_transformer(self.origin),
        coord_transformer(Point(self.origin:value() + self.direction * 2)),
        color,
        scale * 0.5
    )
end

local Assert = require('drift-mode.assert')
local function test()
end
test()

return StartingPoint
