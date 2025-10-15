local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@class Poi : ModelBase
---@field point Point
local Poi = class("Poi", ModelBase)
Poi.__model_path = "Elements.Poi"

function Poi:initialize(point)
    self.point = point
end

---@param element Element
---@return Poi[]
function Poi:gatherPois(element)
    Assert.Error("Abstract method called")
    return {}
end

---@param context EditorRoutine.Context
function Poi:onDelete(context)

end

function Poi:set(new_pos)
    Assert.Error("Abstract method called")
end

return Poi
