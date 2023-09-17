local Assert = require('drift-mode/assert')
local EventSystem = require('drift-mode/eventsystem')
local S = require('drift-mode/serializer')

---@class CursorObject : ClassBase Data class containing various objects you may want to draw on the track, that are not related to track configuration
---@field object any
---@field drawer Drawer
local CursorObject = class("CursorObject")

function CursorObject:initialize(object, drawer)
    self.object = object
    self.drawer = drawer
end

function CursorObject:draw()
    self.drawer:draw(self.object)
end

local function test()
end
test()

return CursorObject
