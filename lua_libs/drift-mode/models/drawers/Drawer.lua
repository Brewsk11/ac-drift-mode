local Assert = require('drift-mode/assert')
local ModelBase = require("drift-mode.models.ModelBase")


---Abstract class
---@class Drawer : ClassBase
local Drawer = class("Drawer", ClassBase)
Drawer.__model_path = "Drawers.Drawer"

function Drawer:initialize()
    Assert.Error("Abstract object called")
end

---@param obj WorldObject
function Drawer:draw(obj)
    Assert.Error("Abstract object called")
end

return Drawer
