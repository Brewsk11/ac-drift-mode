local Assert = require('drift-mode.assert')

---Base class for model classes that are expected to be serialized.
---@class ModelBase : ClassBase
---@field __cache table<string, { [string]: any }> Cache table for the cache system; non-serializable
---@field __observers ModelBase[] Table of observers for changes for the cache system; non-serializable
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

---@param callback fun(observer: ModelBase)? By default calls `self:setDirty()`
function ModelBase:registerObserver(callback)
    table.insert(self.__observers, callback)
end

function ModelBase:unregisterObserver(callback)
    for idx, c in ipairs(self.__observers) do
        if c == callback then
            table.remove(self.__observers, idx)
            break
        end
    end
end

---@protected
function ModelBase:notifyDirty()
    for _, callback in ipairs(self.__observers) do
        callback()
    end
end

-- Wrap a method so that its return value is cached.
-- `keyBuilder` receives the original arguments (including `self`) and
-- must return a string that uniquely represents the call.
function ModelBase:cacheMethod(method_name, key_builder)
    self.__cache[method_name] = {}
    local original_method = self[method_name]

    Assert.NotNil(original_method, "Method " .. tostring(method_name) .. " does not exist")

    --  local key_builder = function(_self, ...) return tostring(select(1, ...)) end

    local function wrapped_method(_self, ...)
        ac.log("calling wrapped " .. method_name)

        local call_key = key_builder(_self, ...)
        local method_cache = self.__cache[method_name]
        if method_cache and method_cache[call_key] ~= nil then
            return method_cache[call_key]
        end
        local res = original_method(self, ...)

        self.__cache[method_name][call_key] = res
        return res
    end

    self[method_name] = wrapped_method
end

-- Base dirty flag – called by observers.
-- Sub‑classes override to reset their own caches.
function ModelBase:setDirty()
    -- Clears *all* caches of this instance
    self._cache = {}
end

function ModelBase:setModelPath(model_path)
end

function ModelBase:setAbbrev(abbrev)
end

function ModelBase:subclassed(classDefinition)
end

return ModelBase
