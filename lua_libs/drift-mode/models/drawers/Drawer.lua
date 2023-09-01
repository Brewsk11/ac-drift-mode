local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---Abstract class
---@class Drawer : ClassBase
local Drawer = class("Drawer")

function Drawer:initialize()
    Assert.Error("Abstract object called")
end

---@param obj WorldObject
function Drawer:draw(obj)
    Assert.Error("Abstract object called")
end


return Drawer
