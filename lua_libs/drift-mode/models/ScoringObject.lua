local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class ScoringObject : WorldObject
local ScoringObject = class("ScoringObject", WorldObject)

function ScoringObject:initialize()
end

local function test()
end
test()

return ScoringObject
