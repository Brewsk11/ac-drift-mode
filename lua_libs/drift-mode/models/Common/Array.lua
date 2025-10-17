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
    ModelBase.initialize(self)
    self._items = items or {}
end

function Array:setDirty()
    ModelBase.setDirty(self)
    for _, item in ipairs(self:getItems()) do
        item:setDirty()
    end
end

---@generic T
---@param item T
function Array:append(item)
    self._items[#self._items + 1] = item
    self:setDirty()
end

---@return integer
function Array:count()
    return #self._items
end

---Get an item from the group
---@generic T
---@param idx integer Index of the item in the group
---@return T
function Array:get(idx)
    assert(self:count() >= idx, "Index (" .. tostring(idx) .. ") out of range (" .. self:count() .. ")")
    return self._items[idx]
end

---Get an item from the group
---@generic T
---@param idx integer Index of the item in the group
---@param value T
function Array:set(idx, value)
    table.insert(self:getItems(), idx, value)
    self:setDirty()
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

---Return an iterator like `ipairs()` iterating over items
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
    self:setDirty()
    return item
end

---Remove item at index
---@generic T
---@param idx integer
---@return T
function Array:remove(idx)
    Assert.LessOrEqual(idx, self:count(), "Out-of-bounds error")
    local item = self._items[idx]
    table.remove(self._items, idx)
    self:setDirty()
    return item
end

---Remove item equal to `item`
---@generic T
---@param item T
---@return boolean deleted True if deleted any item
function Array:delete(item)
    local removed = table.removeItem(self._items, item)
    if removed then
        self:setDirty()
    end
    return removed
end

local function test()
    -- Array()
    local grp = Array()
    Assert.NotEqual(grp._items, nil, "Empty constructor did not initialize segment table")
    Assert.Equal(#grp._items, 0, "Segment table length not zero")
end
test()

return class.emmy(Array, Array.initialize)
