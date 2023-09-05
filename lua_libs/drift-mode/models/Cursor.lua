local Assert = require('drift-mode/assert')
local EventSystem = require('drift-mode/eventsystem')
local S = require('drift-mode/serializer')

---@class Cursor : ClassBase Data class containing various objects you may want to draw on the track, that are not related to track configuration
---@field selector Point?
---@field color_selector rgbm?
---@field point_group_a PointGroup?
---@field point_group_b PointGroup?
---@field color_a rgbm?
---@field color_b rgbm?
local Cursor = class("Cursor")

---@overload fun()
function Cursor:initialize(
    selector,
    color_selector,
    point_group_a,
    point_group_b,
    color_a,
    color_b
)
    self.selector = selector
    self.color_selector = color_selector or rgbm(3, 0, 0, 1)
    self.point_group_a = point_group_a
    self.point_group_b = point_group_b
    self.color_a = color_a or rgbm(0, 3, 0, 1)
    self.color_b = color_b or rgbm(0, 0, 3, 1)

    -- TODO: Cleanup
    ---@type DrawerSegment
    self.drawer_segment = DrawerSegmentLine(rgbm(1, 3, 1, 3))
end

function Cursor:serialize()
    local _selector = nil
    local _point_group_a = nil
    local _point_group_b = nil
    if self.selector then _selector = self.selector:serialize() end
    if self.point_group_a then _point_group_a = self.point_group_a:serialize() end
    if self.point_group_b then _point_group_b = self.point_group_b:serialize() end
    local data = {
        __class = "Cursor",
        selector = _selector,
        color_selector = S.serialize(self.color_selector),
        point_group_a = _point_group_a,
        point_group_b = _point_group_b,
        color_a = S.serialize(self.color_a),
        color_b = S.serialize(self.color_b)
    }
    return data
end

function Cursor.deserialize(data)
    Assert.Equal(data.__class, "Cursor", "Tried to deserialize wrong class")

    local _selector = nil
    local _point_group_a = nil
    local _point_group_b = nil
    if data.selector then _selector = Point.deserialize(data.selector) end
    if data.point_group_a then _point_group_a = PointGroup.deserialize(data.point_group_a) end
    if data.point_group_b then _point_group_b = PointGroup.deserialize(data.point_group_b) end

    local obj = Cursor(
        _selector,
        S.deserialize(data.color_selector),
        _point_group_a,
        _point_group_b,
        S.deserialize(data.color_a),
        S.deserialize(data.color_b)
    )
    return obj
end

function Cursor:reset()
    self.selector = nil
    self.color_selector = rgbm(3, 0, 0, 1)
    self.point_group_a = nil
    self.point_group_b = nil
    self.color_a = rgbm(0, 3, 0, 1)
    self.color_b = rgbm(0, 0, 3, 1)
    EventSystem.emit(EventSystem.Signal.CursorChanged, self)
end

function Cursor:draw()
    if self.selector then
        render.debugPoint(self.selector:value(), 0.3, self.color_selector)
        render.debugSphere(self.selector:value(), 1, rgbm(self.color_selector.r, self.color_selector.g, self.color_selector.b, 0.7))
    end

    if self.point_group_a then
        self.point_group_a:draw(0.3, self.color_a, true)
        self.point_group_a:segment():draw(self.color_a)
    end

    if self.point_group_b then
        for _, segment in self.point_group_b:segment():iter() do
            self.drawer_segment:draw(segment)
        end
    end
end

local function test()
end
test()

return Cursor
