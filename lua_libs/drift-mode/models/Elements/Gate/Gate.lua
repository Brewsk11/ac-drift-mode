local Element = require("drift-mode.models.Elements.Element")
local Point = require("drift-mode.models.Common.Point.Point")
local Handle = require("drift-mode.models.Elements.Gate.Handle")

---@class Gate : Element
---@field private segment Segment
local Gate = class("Gate", Element)
Gate.__model_path = "Elements.Gate.Gate"

---@param segment Segment
function Gate:initialize(name, segment)
    Element.initialize(self, name)
    self.segment = segment

    self:registerDefaultObservers()
end

function Gate:registerDefaultObservers()
    if self.segment then self.segment:registerObserver(self) end
end

function Gate:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawCircleFilled(coord_transformer(self.origin), scale * 1, color)
    ui.drawLine(
        coord_transformer(self.origin),
        coord_transformer(Point(self.origin:value() + self.direction * 2)),
        color,
        scale * 0.5
    )
end

function Gate:getCenter()
    if self.segment then return self.segment:getCenter() end
    return nil
end

function Gate:gatherHandles()
    local handles = {}

    if self.segment ~= nil then
        handles[#handles + 1] = Handle(
            self.segment:getHead(),
            self,
            Handle.Type.Head
        )

        handles[#handles + 1] = Handle(
            self.segment:getTail(),
            self,
            Handle.Type.Tail
        )

        handles[#handles + 1] = Handle(
            self.segment:getCenter(),
            self,
            Handle.Type.Center
        )
    end

    return handles
end

local Assert = require('drift-mode.assert')
local function test()
end
test()

return Gate
