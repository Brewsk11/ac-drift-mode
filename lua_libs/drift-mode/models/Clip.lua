local Assert = require('drift-mode/assert')

local Point = require('drift-mode.models.Common.Point')
local ScoringObject = require("drift-mode.models.ScoringObject")
local Segment = require("drift-mode.models.Segment")

---@class Clip : ScoringObject Class representing a drift scoring zone
---@field name string Name of the zone
---@field origin Point
---@field direction vec3
---@field length number
---@field maxPoints integer Maximum points possible to score for the clip (in a perfect run)
---@field private collide boolean Whether to enable colliders for this clip
---@field private lastPoint Point To calculate where crossed
local Clip = class("Clip", ScoringObject)
Clip.__model_path = "Clip"

---@param name string
---@param origin Point
---@param direction vec3
---@param length number
---@param maxPoints integer
function Clip:initialize(name, origin, direction, length, maxPoints, collide)
    self.name = name
    self.origin = origin
    self.direction = direction
    self.length = length
    self.maxPoints = maxPoints
    self.collide = collide or true
end

function Clip:getEnd()
    return Point(self.origin:value() + self.direction * self.length)
end

function Clip:setEnd(new_end_point)
    self.direction = (new_end_point:value() - self.origin:value()):normalize()
    self.length = new_end_point:value():distance(self.origin:value())
end

function Clip:getLength()
    return self.length
end

function Clip:getCenter()
    return self:getSegment():getCenter()
end

function Clip:gatherColliders()
    if not self.collide then return {} end

    local direction = (self:getEnd():value() - self.origin:value()):normalize()
    local look = vec3()
    look:set(direction):cross(vec3(0, 1, 0))

    local collider = {
        physics.Collider.Box(
            vec3(1, 1, 0.01),
            self.origin:value() + vec3(0, 0.5, 0) - 0.5 * direction,
            look,
            vec3(0, 1, 0),
            false
        )
    }

    return collider
end

function Clip:setCollide(value)
    self.collide = value
end

function Clip:getCollide()
    return self.collide
end

function Clip:getSegment()
    return Segment(self.origin, self:getEnd())
end

function Clip:getBoundingBox()
    if self.origin == nil then
        return nil
    end

    local pMin = vec3(9999, 9999, 9999)
    local pMax = vec3(-9999, -9999, -9999)

    pMin:min(self.origin:value())
    pMax:max(self.origin:value())

    pMin:min(self:getEnd():value())
    pMax:max(self:getEnd():value())

    return { p1 = Point(pMin), p2 = Point(pMax) }
end

function Clip:drawFlat(coord_transformer, scale)
    local origin_mapped = coord_transformer(self.origin)
    local end_mapped = coord_transformer(self:getEnd())
    ui.drawLine(origin_mapped, end_mapped, rgbm.colors.white, 0.5 * scale)
    ui.drawCircleFilled(origin_mapped, 1 * scale, rgbm.colors.white)
end

local function test()
    local test_clip = Clip("TestBoundingBox", Point(vec3(-1, 1, -1)))
    test_clip:setEnd(Point(vec3(1, -1, 1)))
    Assert.Equal(test_clip:getBoundingBox().p1:value(), vec3(-1, -1, -1))
    Assert.Equal(test_clip:getBoundingBox().p2:value(), vec3(1, 1, 1))
end
test()

return Clip
