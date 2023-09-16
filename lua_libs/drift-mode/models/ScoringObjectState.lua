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

function ScoringObjectState:__serialize()
    if self.isInstanceOf(ZoneState) then
        return ZoneState.__serialize(self)
    elseif self.isInstanceOf(ClipState) then
        return ClipState.__serialize(self)
    else
        Assert.Error("")
    end
end

local function test()
end
test()

return ScoringObjectState
