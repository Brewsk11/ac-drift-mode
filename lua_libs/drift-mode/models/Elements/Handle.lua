local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---Class for world-space handles to modify elements
---@class Handle : ModelBase
---@field point Point
local Handle = class("Handle", ModelBase)
Handle.__model_path = "Elements.Handle"

function Handle:initialize(point)
    self.point = point
end

---@param context EditorRoutine.Context
function Handle:onDelete(context)

end

---@param new_pos  Point
function Handle:set(new_pos)
    Assert.Error("Abstract method called")
end

return Handle
