local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Zone Class representing a drift scoring zone
---@field name string Name of the zone
---@field outsideLine PointGroup Outside zone line definition
---@field insideLine PointGroup Inside zone line definition
---@field maxPoints integer Maximum points possible to score in the zone (in a perfect run) 
local Zone = {}
Zone.__index = Zone

function Zone.serialize(self)
    local data = {
        __class = "Zone",
        name = S.serialize(self.name),
        outsideLine = self.outsideLine:serialize(),
        insideLine = self.insideLine:serialize(),
        maxPoints = S.serialize(self.maxPoints)
    }
    return data
end

function Zone.deserialize(data)
    Assert.Equal(data.__class, "Zone", "Tried to deserialize wrong class")

    local obj = Zone.new(
        S.deserialize(data.name),
        PointGroup.deserialize(data.outsideLine),
        PointGroup.deserialize(data.insideLine),
        S.deserialize(data.maxPoints)
    )
    return obj
end

---@param name string
---@param outsideLine PointGroup
---@param insideLine PointGroup
---@param maxPoints integer
---@return Zone
function Zone.new(name, outsideLine, insideLine, maxPoints)
    local self = setmetatable({}, Zone)

    self.name = name
    self.outsideLine = outsideLine
    self.insideLine = insideLine
    self.maxPoints = maxPoints
    return self
end

local Assert = require('drift-mode/assert')
local function test()
end
test()

return Zone
