local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringObject : ClassBase
local ScoringObject = class("ScoringObject")

function ScoringObject:initialize()
end

---Get visual center of the object.
---Used mainly for visualization, so doesn't need to be accurate.
function ScoringObject:getCenter()
    Assert.Error("Called abstract method!")
end

---Draw itself using ui.* calls
---@param coord_transformer fun(vec2) Function converting true coordinate to canvas coordinate
function ScoringObject:drawFlat(coord_transformer)
    Assert.Error("Called abstract method!")
end

function ScoringObject:getBoundingBox()
    Assert.Error("Called abstract method!")
end

local function test()
end
test()

return ScoringObject
