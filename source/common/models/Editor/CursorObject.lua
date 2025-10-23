local ModelBase = require("drift-mode.models.ModelBase")
---@class CursorObject : ClassBase Data class containing various objects you may want to draw on the track, that are not related to track configuration
---@field object any
---@field drawer Drawer
local CursorObject = class("CursorObject", ModelBase)
CursorObject.__model_path = "Editor.CursorObject"

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
