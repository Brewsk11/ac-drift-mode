local Assert = require('drift-mode.assert')

---Base class for model classes that are expected to be serialized.
---@class ModelBase : ClassBase
---@field __cache { [string]: { [string]: any }} Cache table for the cache system; non-serializable
---@field __observers table<ModelBase, function> of observers for changes for the cache system; non-serializable
---@field __serialize function?
---@field __deserialize function?
local ModelBase = class("ModelBase", ClassBase)
ModelBase.__model_path = "ModelBase"

---@alias ModelDefinition {__name: string, __model_path: string, __deserialize: function|nil, __serialize: function|nil, test: function|nil}

---@type table<string, ModelDefinition>
ModelBase.PathToAbbrev = {}
ModelBase.AbbrevToPath = {}

---@overload fun()
function ModelBase:initialize()
    self.__observers = {}
    self.__cache = {}
end

---Defines fields not to be serialized
---Ignored for custom serializers
function ModelBase:isSerializerExempt(field_name)
    if field_name == "__cache" or field_name == "__observers" then
        return true
    end
    return false
end

---@param observer ModelBase
---@param callback fun() By default calls `self:setDirty()`
function ModelBase:registerObserver(observer, callback)
    self.__observers = self.__observers or {}
    self.__observers[observer] = callback
end

function ModelBase:unregisterObserver(observer)
    if self.__observers == nil then return false end
    return table.removeItem(self.__observers, observer)
end

---@private
function ModelBase:notifyObservers()
    for _, callback in ipairs(self.__observers) do
        callback()
    end
end

-- Base dirty flag – called by observers.
-- Sub‑classes override to reset their own caches.
function ModelBase:setDirty()
    -- Clears *all* caches of this instance
    self.__cache = {}
    self:notifyObservers()
end

local NIL = {}

-- Wrap a method so that its return value is cached.
-- `keyBuilder` receives the original arguments (including `self`) and
-- must return a string that uniquely represents the call.
function ModelBase:cacheMethod(method_name, key_builder)
    self.__cache = self.__cache or {}
    self.__cache[method_name] = {}
    local original_method = self[method_name]

    Assert.NotNil(original_method, "Method " .. tostring(method_name) .. " does not exist")

    local _key_builder = key_builder or function(_self, ...)
        if select('#', ...) == 0 then
            return "__no_args"
        end
        return tostring(select(1, ...))
    end

    local function wrapped_method(_self, ...)
        local call_key = _key_builder(_self, ...)
        local method_cache = self.__cache[method_name]
        local cached = method_cache[call_key]

        if cached ~= nil then -- hit
            return cached == NIL and nil or cached
        end

        local res = original_method(self, ...)

        -- Store the result, replacing `nil` with the sentinel
        method_cache[call_key] = (res == nil) and NIL or res
        return res
    end

    self[method_name] = wrapped_method
end

function ModelBase:setModelPath(model_path)
end

function ModelBase:setAbbrev(abbrev)
end

function ModelBase:subclassed(classDefinition)
end

return ModelBase
