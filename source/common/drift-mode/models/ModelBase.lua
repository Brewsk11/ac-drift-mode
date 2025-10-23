local Assert = require('drift-mode.Assert')

---Base class for model classes that are expected to be serialized.
---@class ModelBase : ClassBase
---@field __cache { [string]: { [string]: any }} # Cache table for the cache system; non-serializable
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
    self.__cache = {}
end

---Defines fields not to be serialized
---Ignored for custom serializers
function ModelBase:isSerializerExempt(field_name)
    if field_name == "__cache" then
        return true
    end
    return false
end

-- Base dirty flag – called by observers.
-- Sub‑classes override to reset their own caches.
function ModelBase:setDirty()
    -- Clears *all* caches of this instance
    self.__cache = {}
end

local NIL = {}

-- Wrap a method so that its return value is cached.
-- `keyBuilder` receives the original arguments (including `self`) and
-- must return a string that uniquely represents the call.
function ModelBase:cacheMethod(method_name, key_builder)
    self.__cache = self.__cache or {}

    local original_method = self[method_name]

    Assert.NotNil(original_method, "Method " .. tostring(method_name) .. " does not exist")

    local _key_builder = key_builder or function(_self, ...)
        if select('#', ...) == 0 then
            return "__no_args"
        end
        return tostring(select(1, ...))
    end

    local function wrapped_method(_self, ...)
        self.__cache[method_name] = self.__cache[method_name] or {}

        local call_key = _key_builder(_self, ...)
        local method_cache = self.__cache[method_name]
        local cached = method_cache[call_key]

        if cached ~= nil then -- hit
            if cached == NIL then
                return nil
            else
                return cached
            end
        end

        local res = original_method(self, ...)

        if res == nil then
            method_cache[call_key] = NIL
        else
            method_cache[call_key] = res
        end
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

function ModelBase.test()
    ---@class TestClass : ModelBase
    local TestClass = class('test_class', ModelBase)
    TestClass.__model_path = "ModelBase"
    function TestClass:initialize()
        ModelBase.initialize(self)
        self.value = 1
        self:cacheMethod("getValue")
    end

    function TestClass:getValue()
        return self.value
    end

    local obj = TestClass()
    Assert.Equal(obj:getValue(), 1)
    obj.value = 2
    Assert.Equal(obj:getValue(), 1)
    obj:setDirty()
    Assert.Equal(obj:getValue(), 2)
end

return ModelBase
