local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringObjectState : ClassBase
local ScoringObjectState = class("ScoringObjectState", WorldObject)

function ScoringObjectState:initialize()
end

function ScoringObjectState:getScore()
    Assert.Error("Abstract method called")
end

function ScoringObjectState:getMaxScore()
    Assert.Error("Abstract method called")
end

---Draw itself using ui.* calls
---@param coord_transformer fun(point: Point): vec2 Function converting true coordinate to canvas coordinate
function ScoringObjectState:drawFlat(coord_transformer)
    Assert.Error("Called abstract method!")
end

local function test()
end
test()

return ScoringObjectState
