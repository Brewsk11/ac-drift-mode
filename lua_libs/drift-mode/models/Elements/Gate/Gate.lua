local Element = require("drift-mode.models.Elements.Element")
local PointDir = require("drift-mode.models.Common.Point.init")
local Handle = require("drift-mode.models.Elements.Gate.Handle")

---@class Gate : Element
---@field private segment Segment
local Gate = class("Gate", Element)
Gate.__model_path = "Elements.Gate.Gate"

---@param segment Segment
function Gate:initialize(name, segment)
    Element.initialize(self, name)
    self.segment = segment
end

function Gate:setDirty()
    Element.setDirty(self)
    if self.segment then self.segment:setDirty() end
end

function Gate:drawFlat(coord_transformer, scale, color)
    -- TODO: Dep injection
    ui.drawCircleFilled(coord_transformer(self.origin), scale * 1, color)
    ui.drawLine(
        coord_transformer(self.origin),
        coord_transformer(PointDir.Point(self.origin:value() + self.direction * 2)),
        color,
        scale * 0.5
    )
end

function Gate:getCenter()
    if self.segment then return self.segment:getCenter() end
    return nil
end

---@return { [HandleId]: GateHandle }
function Gate:gatherHandles()
    local handles = {}
    local prefix = self:getId() .. "_"

    if self.segment ~= nil then
        handles[prefix .. Handle.Type.Head] = Handle(
            self.segment:getHead(),
            self,
            Handle.Type.Head,
            PointDir.Drawers.Simple(rgbm(1, 1, 0, 1), 0.3)
        )

        handles[prefix .. Handle.Type.Tail] = Handle(
            self.segment:getTail(),
            self,
            Handle.Type.Tail,
            PointDir.Drawers.Simple(rgbm(1, 1, 0, 1), 0.3)
        )

        handles[prefix .. Handle.Type.Center] = Handle(
            self.segment:getCenter(),
            self,
            Handle.Type.Center,
            PointDir.Drawers.Simple(rgbm(1, 0, 1, 1), 0.1)
        )
    end

    return handles
end

local Assert = require('drift-mode.assert')
local function test()
end
test()

return Gate
