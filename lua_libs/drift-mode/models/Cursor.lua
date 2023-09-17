local Assert = require('drift-mode/assert')
local EventSystem = require('drift-mode/eventsystem')
local S = require('drift-mode/serializer')

---@class Cursor : ClassBase Data class containing various objects you may want to draw on the track, that are not related to track configuration
---@field objects table<string, CursorObject>
local Cursor = class("Cursor")

function Cursor:initialize()
    self.objects = {}
end

function Cursor:reset()
    table.clear(self.objects)
end

function Cursor:registerObject(id, object, drawer)
    ac.log("pre", S.serialize(self.objects))
    self.objects[id] = CursorObject(object, drawer)
    ac.log("post", S.serialize(self.objects))
    EventSystem.emit(EventSystem.Signal.CursorChanged, self)
end

function Cursor:unregisterObject(id)
    self.objects[id] = nil
    EventSystem.emit(EventSystem.Signal.CursorChanged, self)
end

function Cursor:draw()
    for _, object in pairs(self.objects) do
        object:draw()
    end
end

local function test()
end
test()

return Cursor
