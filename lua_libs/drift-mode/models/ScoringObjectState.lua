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

local function test()
end
test()

return ScoringObjectState
