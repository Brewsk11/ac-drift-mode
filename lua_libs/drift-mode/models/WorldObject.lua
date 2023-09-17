local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---Base class for object that can be drawn in the world space
---@class WorldObject : ClassBase
---@field protected drawer Drawer?
local WorldObject = class("WorldObject")

function WorldObject:initialize()
end

function WorldObject:draw()
    if self.drawer then
        self.drawer:draw(self)
    end
end

function WorldObject:getDrawer()
    return self.drawer()
end

---@param drawer Drawer?
function WorldObject:setDrawer(drawer)
    self.drawer = drawer
end

---@returns Point?
function WorldObject:getVisualCenter()
    Assert.Error("Abstract method called")
end

return WorldObject
