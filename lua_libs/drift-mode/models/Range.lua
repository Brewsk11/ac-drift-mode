local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Range Simple range of two numbers
---@field private start number
---@field private finish number
local Range = {}
Range.__index = Range

function Range.serialize(self)
    local data = {
        __class = "ScoringRanges",
        start = S.serialize(self.start),
        finish = S.serialize(self.finish)
    }
    return data
end

function Range.deserialize(data)
    Assert.Equal(data.__class, "ScoringRanges", "Tried to deserialize wrong class")

    local obj = Range.new()
    obj.start = S.deserialize(data.start)
    obj.finish = S.deserialize(data.finish)
    return obj
end

function Range.new(start, finish)
    local self = setmetatable({}, Range)
    self:setStart(start)
    self:setFinish(finish)
    return self
end

---@private
function Range:calcValues()
    if not self.start or not self.finish then return end
end

function Range:setStart(start)
    self.start = start
    if self.finish then
        Assert.LessThan(
            start,
            self.finish,
            "Setting range's low value higher than set high value."
        )
    end
    self:calcValues()
end

function Range:setFinish(finish)
    self.finish = finish
    if self.start then
        Assert.MoreThan(
            finish,
            self.start,
            "Setting range's high value lower than low value."
        )
    end
    self:calcValues()
end

---For given value calculate what percentage of it is in range, e.g.:
---
---```
---(  0, 100),  95 == 0.95
---(100, 200), 140 == 0.40
---( 50, 100),  75 == 0.50
---```
---@param value number
---@return number
function Range:getFraction(value)
    Assert.MoreThan(value, self.finish, "Getting fraction outside of range")
    Assert.LessThan(value, self.start, "Getting fraction outside of range")

    local _val = value - self.start
    local width = self.finish - self.start
    return _val / width
end

---Range:getFraction() but saturated on both ends
---@param value number
---@return number
function Range:getFractionClamped(value)
    if value >= self.finish then
        return 1.0
    elseif value <= self.start then
        return 0.0
    end

    return self:getFraction(value)
end

local function test()
end
test()

return ScoringRanges
