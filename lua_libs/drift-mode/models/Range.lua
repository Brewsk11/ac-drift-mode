local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class Range Simple range of two numbers
---@field start number
---@field finish number
local Range = {}
Range.__index = Range

function Range.serialize(self)
    local data = {
        __class = "Range",
        start = S.serialize(self.start),
        finish = S.serialize(self.finish)
    }
    return data
end

function Range.deserialize(data)
    Assert.Equal(data.__class, "Range", "Tried to deserialize wrong class")

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
    Assert.LessThan(value, self.finish, "Getting fraction outside of range")
    Assert.MoreThan(value, self.start, "Getting fraction outside of range")

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
    local range = Range.new(0, 100)
    Assert.Equal(range:getFractionClamped(50), 0.5)
    Assert.Equal(range:getFractionClamped(75), 0.75)
    Assert.Equal(range:getFractionClamped(100), 1.0)
    Assert.Equal(range:getFractionClamped(101), 1.0)

    local range = Range.new(0, 50)
    Assert.Equal(range:getFractionClamped(10), 0.2)
    Assert.Equal(range:getFractionClamped(25), 0.5)

    local range = Range.new(100, 150)
    Assert.Equal(range:getFractionClamped(-100), 0.0)
    Assert.Equal(range:getFractionClamped(110), 0.2)
    Assert.Equal(range:getFractionClamped(125), 0.5)
end
test()

return Range
