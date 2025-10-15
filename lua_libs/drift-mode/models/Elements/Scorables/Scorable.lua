local Element = require("drift-mode.models.Elements.Element")
local Assert = require('drift-mode.assert')

---@class Scorable : Element
local Scorable = class("ScoringObject", Element)
Scorable.__model_path = "Elements.Scorables.Scorable"

function Scorable:initialize(name, maxPoints)
    Element.initialize(self, name)
    self.maxPoints = maxPoints
end

-- TODO: getStateObject()

local function test()
end
test()

return class.emmy(Scorable, Scorable.initialize)
