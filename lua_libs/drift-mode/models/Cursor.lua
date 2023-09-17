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
    -- Check if new object is the same and skip for performance (~10ms)
    local are_same, _, _  = S.traverse_object(self.objects[id], { object, drawer })

    if not are_same then
        self.objects[id] = CursorObject(object, drawer)
        EventSystem.emit(EventSystem.Signal.CursorChanged, self)
    end
end

function Cursor:unregisterObject(id)
    -- Check if new object is the same and skip for performance (~10ms)
    if self.objects[id] ~= nil then
        self.objects[id] = nil
        EventSystem.emit(EventSystem.Signal.CursorChanged, self)
    end
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
