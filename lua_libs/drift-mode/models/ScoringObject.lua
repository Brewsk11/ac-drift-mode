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

local function test()
end
test()

return ScoringObject
