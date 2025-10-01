local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode/assert')

---@class ScoringObject : ClassBase
local ScoringObject = class("ScoringObject", ModelBase)
ScoringObject.__model_path = "Elements.Scorables.ScoringObject"

function ScoringObject:initialize()
end

---Get visual center of the object.
---Used mainly for visualization, so doesn't need to be accurate.
function ScoringObject:getCenter()
    Assert.Error("Called abstract method!")
end

---Draw itself using ui.* calls
---@param coord_transformer fun(Point): vec2 Function converting true coordinate to canvas coordinate
function ScoringObject:drawFlat(coord_transformer, scale)
    Assert.Error("Called abstract method!")
end

function ScoringObject:getBoundingBox()
    Assert.Error("Called abstract method!")
end

-- TODO: getStateObject()

local function test()
end
test()

return ScoringObject
