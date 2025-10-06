local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---@generic T
---@class Array<T> : ModelBase
---@field private _items T[]
local Array = class("Collection", ModelBase)
Array.__model_path = "Common.Array"

---@generic T
---@overload fun(): Array<T>
---@overload fun(items: T[]): Array<T>
---@return Array<T>
function Array:initialize(items)
    self._items = items or {}
end

---@generic T
---@param item T
function Array:append(item)
    self._items[#self._items + 1] = item
end

---@return integer
function Array:count()
    return #self._items
end

---Get a point from the group
---@generic T
---@param idx integer Index of the point in the group
---@return T
function Array:get(idx)
    assert(self:count() >= idx, "Index (" .. tostring(idx) .. ") out of range (" .. self:count() .. ")")
    return self._items[idx]
end

---@generic T
---@protected
---@return T[]
function Array:getItems()
    return self._items
end

---Get first item
---@generic T
---@return T?
function Array:first()
    if self:count() == 0 then return nil end
    return self._items[1]
end

---Get last item
---@generic T
---@return T?
function Array:last()
    if self:count() == 0 then return nil end
    return self._items[#self._items]
end

---Return an iterator like `ipairs()` iterating over points
---@generic T
---@return (fun(): integer, T), T[], integer
function Array:iter()
    return ipairs(self._items)
end

---@generic T
---@return T
function Array:pop()
    local item = self._items[self:count()]
    self._items[self:count()] = nil
    return item
end

---Remove point at index
---@generic T
---@param idx integer
---@return T
function Array:remove(idx)
    Assert.LessOrEqual(idx, self:count(), "Out-of-bounds error")
    local item = self._items[idx]
    table.remove(self._items, idx)
    return item
end

---Remove item equal to `item`
---@generic T
---@param item T
---@return boolean deleted True if deleted any point
function Array:delete(item)
    return table.removeItem(self._items, item)
end

local function test()
    -- Array()
    local grp = Array()
    Assert.NotEqual(grp._items, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(#grp._items, 0, "Segment table length not zero")
end
test()

return class.emmy(Array, Array.initialize)
