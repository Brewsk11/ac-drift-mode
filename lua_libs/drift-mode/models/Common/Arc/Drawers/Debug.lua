local DrawerArc = require("drift-mode.models.Common.Arc.Drawers.Base")
local Circle = require("drift-mode.models.Common.Circle")

---@class DrawerArcDebug : DrawerArc
local DrawerArcDebug = class("DrawerArcDebug", DrawerArc)
DrawerArcDebug.__model_path = "Common.Arc.Drawers.Debug"

function DrawerArcDebug:initialize(color)
    DrawerArc.initialize(self)
    self.color = color or rgbm(1, 1, 1, 1)
end

---@param arc Arc
function DrawerArcDebug:draw(arc)
    render.debugArrow(arc:getCenter():value(), arc:getCenter():value() + arc:getNormal(), 0.1, rgbm(0, 3, 0, 1))
    render.debugArrow(arc:getCenter():value(),
        arc:getCenter():value() + arc:getNormal():clone():cross(vec3(1, 0, 0)):normalize() * arc:getRadius(), 0.1,
        rgbm(3, 0, 0, 1))

    -- self:toPointArray() would cause this call to route to Arc:toPointArray()
    -- if called from Arc:drawDebug()
    local segments = Circle.toPointArray(arc, self:getN(arc)):segment(true)

    for _, seg in segments:iter() do
        render.debugLine(seg.head:value(), seg.tail:value(), rgbm(3, 0, 0, 1) * 0.4)
    end

    local segments2 = arc:toPointArray(self:getN(arc)):segment(false)

    for _, segment in segments2:iter() do
        render.debugLine(segment.head:value(), segment.tail:value(), rgbm(0, 0, 3, 1))
    end

    render.debugArrow(arc:getCenter():value(), arc:getCenter():value() + arc:getStartDirection() * arc:getRadius(),
        -1, rgbm(0, 0, 3, 1))
    render.debugArrow(arc:getCenter():value(), arc:getCenter():value() + arc:getEndDirection() * arc:getRadius(), -1,
        rgbm(0, 1, 3, 1))

    render.debugPoint(arc:getStartPoint():value())
    render.debugPoint(arc:getEndPoint():value())
end

return DrawerArcDebug
