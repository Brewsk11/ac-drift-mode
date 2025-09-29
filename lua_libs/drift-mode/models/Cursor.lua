local ModelBase = require("drift-mode.models.ModelBase")
local EventSystem = require('drift-mode.eventsystem')

local CursorObject = require("drift-mode.models.CursorObject")

---@class Cursor : ClassBase Data class containing various objects you may want to draw on the track, that are not related to track configuration
---@field objects table<string, CursorObject>
local Cursor = class("Cursor", ModelBase)
Cursor.__model_path = "Cursor"

function Cursor:initialize()
    self.objects = {}
end

function Cursor:reset()
    table.clear(self.objects)
end

function Cursor:registerObject(id, object, drawer)
    local S = require('drift-mode.serializer') -- TODO: Maybe this doesn't have to require() serializer?
    -- Check if new object is the same and skip for performance (~10ms)
    local are_same, _, _ = S.checkEqual(self.objects[id], { object, drawer })

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
    for key, object in pairs(self.objects) do
        if object.object == nil then
            -- Self GC
            self.objects[key] = nil
        else
            object:draw()
        end
    end
end

local function test()
end
test()

return Cursor
