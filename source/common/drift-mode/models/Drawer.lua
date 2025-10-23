local Assert = require('drift-mode.assert')
local ModelBase = require("drift-mode.models.ModelBase")

---Abstract class
---@class Drawer : ModelBase
local Drawer = class("Drawer", ModelBase)
Drawer.__model_path = "Drawer"

function Drawer:initialize()
    ModelBase.initialize(self)
end

---@param obj any
function Drawer:draw(obj)
    Assert.Error("Abstract object called")
end

return Drawer
