local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@class Element : ModelBase
local Element = class("ScoringObject", ModelBase)
Element.__model_path = "Elements.Element"

function Element:initialize(name)
    ModelBase:initialize()
    self.name = name
end

---Get visual center of the object.
---Used mainly for visualization, so doesn't need to be accurate.
function Element:getCenter()
    Assert.Error("Called abstract method!")
end

---@return physics.ColliderType[]
function Element:gatherColliders()
    Assert.Error("Called abstract method!")
    return {}
end

---Draw itself using ui.* calls
---@param coord_transformer fun(Point): vec2 Function converting true coordinate to canvas coordinate
---@param scale number
function Element:drawFlat(coord_transformer, scale)
    Assert.Error("Called abstract method!")
end

function Element:getBoundingBox()
    Assert.Error("Called abstract method!")
end

---@return Handle[]
function Element:gatherHandles()
    return {}
end

local function test()
end
test()

return class.emmy(Element, Element.initialize)
