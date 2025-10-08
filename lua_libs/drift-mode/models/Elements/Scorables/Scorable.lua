local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@class Scorable : ModelBase
local Scorable = class("ScoringObject", ModelBase)
Scorable.__model_path = "Elements.Scorables.Scorable"


function Scorable:initialize(name, maxPoints)
    self.name = name
    self.maxPoints = maxPoints
end

---Get visual center of the object.
---Used mainly for visualization, so doesn't need to be accurate.
function Scorable:getCenter()
    Assert.Error("Called abstract method!")
end

---@return physics.ColliderType[]
function Scorable:gatherColliders()
    Assert.Error("Called abstract method!")
    return {}
end

---Draw itself using ui.* calls
---@param coord_transformer fun(Point): vec2 Function converting true coordinate to canvas coordinate
---@param scale number
function Scorable:drawFlat(coord_transformer, scale)
    Assert.Error("Called abstract method!")
end

function Scorable:getBoundingBox()
    Assert.Error("Called abstract method!")
end

-- TODO: getStateObject()

local function test()
end
test()

return class.emmy(Scorable, Scorable.initialize)
