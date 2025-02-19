local Assert = require('drift-mode/assert')
local json = require('drift-mode/json')

local Serializer = {}

---Serialize custom objects so that they can be encoded as JSON.
---
---Custom classes should have an `Class:serialize(self)` method
---and `Class.deserialize()` class function using `Serializer.serialize()`
---and `Serializer.deserialize()` for primitive types.
---@param data any
---@return any
function Serializer.serialize(data)
    -- CSP class
    if ClassBase.isInstanceOf(data) then
        if data.__serialize == nil then
            -- Classes with no custom de/serializer

            local obj = { __class = data.__name }
            for k, v in pairs(data) do
                obj[k] = Serializer.serialize(v)
            end
            return obj
        else
            -- Classes with customized de/serializer

            Assert.Equal(type(data.__serialize), "function")
            return data:__serialize()
        end
    end

    -- array
    if type(data) == 'table' and data[1] ~= nil then
        local new_data = {}
        for idx, val in ipairs(data) do
            new_data[idx] = Serializer.serialize(val)
        end
        return new_data
    end

    -- table
    if type(data) == 'table' then
        local new_data = { __table = true }
        for el, val in pairs(data) do
            new_data[el] = Serializer.serialize(val)
        end
        return new_data
    end

    -- vec2
    if vec2.isvec2(data) then
        return {
            __vec2 = true,
            x = data.x,
            y = data.y
        }
    end

    -- vec3
    if vec3.isvec3(data) then
        return {
            __vec3 = true,
            x = data.x,
            y = data.y,
            z = data.z
        }
    end

    -- rgbm & rgb
    if rgb.isrgb(data) or rgbm.isrgbm(data) then
        local color = {
            r = data.r,
            g = data.g,
            b = data.b
        }

        if rgbm.isrgbm(data) then
            color.__rgbm = true
            color.mult = data.mult
        else
            color.__rgb = true
        end

        return color
    end

    assert(
        type(data) == "nil" or
        type(data) == "number" or
        type(data) == "string" or
        type(data) == "boolean",
        "Serializing '" .. type(data) .. "' type is not implemented."
    )

    return { __val = data }
end

---Use it to deserialize previously serialized data
---@param data any
---@return any
function Serializer.deserialize(data)
    -- nil
    if data == nil then return nil end

    -- CSP classes
    if data['__class'] ~= nil then
        local obj = nil

        if _G[data.__class].__deserialize == nil then
            -- Classes with no custom de/serializer
            obj = _G[data.__class]()
            for k, v in pairs(data) do
                obj[k] = Serializer.deserialize(v)
            end
        else
            -- Classes with customized de/serializer
            Assert.Equal(type(_G[data.__class].__deserialize), "function")
            obj = _G[data.__class].__deserialize(data)
        end

        -- Additional function to call if any calculation is needed
        -- post obj:initialize()
        if obj.__post_deserialize ~= nil then
            Assert.Equal(type(obj.__post_deserialize), "function")
            obj:__post_deserialize()
        end

        return obj
    end

    -- table
    if data['__table'] ~= nil then
        local new_data = {}
        for el, val in pairs(data) do
            if not string.startsWith(el, '__') then
                new_data[el] = Serializer.deserialize(val)
            end
        end
        return new_data
    end

    -- array
    if type(data) == 'table' and data[1] ~= nil then
        local new_data = {}
        data.__array = nil
        for idx, val in ipairs(data) do
            new_data[idx] = Serializer.deserialize(val)
        end
        return new_data
    end

    -- vec2
    if data['__vec2'] ~= nil then
        return vec2(data.x, data.y)
    end

    -- vec3
    if data['__vec3'] ~= nil then
        return vec3(data.x, data.y, data.z)
    end

    -- rgbm & rgb
    if data['__rgb'] ~= nil then return rgb(data.r, data.g, data.b) end
    if data['__rgbm'] ~= nil then return rgbm(data.r, data.g, data.b, data.mult) end

    return data.__val
end

function Serializer.toJson(data)
    return json.encode(Serializer.serialize(data))
end

function Serializer.checkEqual(prefix, obj_a, obj_b, debug)
    if type(obj_a) ~= "table" and type(obj_b) ~= "table" then
        if debug then ac.log("`" .. prefix .. "` : " .. tostring(obj_a) .. " vs. " .. tostring(obj_b)) end
        return obj_a == obj_b, obj_a, obj_b
    elseif type(obj_a) == "table" and type(obj_b) == "table" then
        for k, v in pairs(obj_a) do
            local res, _obj_a, _obj_b = Serializer.checkEqual(prefix .. "." .. k, v, obj_b[k], debug)
            if not res then
                return res, _obj_a, _obj_b
            end
        end
    else
        if debug then ac.log(tostring(obj_a) .. " ~= " .. tostring(tostring(obj_b))) end
        return false, obj_a, obj_b
    end
    return true, obj_a, obj_b
end

TestClassNested = class("TestClassNested")
function TestClassNested:initialize()
    self.number = math.random(1000)
    self.string = "from_initialize"
    self.nested_table = { table = { number = math.random(1000), float = math.random() } }
end

TestClass = class("TestClass")
function TestClass:initialize()
    self.number = math.random(1000)
    self.string = "from_initialize"
    self.nested_table = { string = 'from_initialize_nested', table = { number = math.random(1000), float = math.random() } }
    self.nested_class = TestClassNested()
    self.nested_class_array = {}
    for i = 1, 2 do
        self.nested_class_array[#self.nested_class_array + 1] = TestClassNested()
    end
end

TestClassCustomSerializer = class("TestClassCustomSerializer")
function TestClassCustomSerializer:initialize()
    self.number = math.random(1000)
end

function TestClassCustomSerializer:__serialize()
    return {
        __class = self.__name,
        custom_number = "abc" .. tostring(self.number) .. "def"
    }
end

function TestClassCustomSerializer.__deserialize(data)
    local obj = TestClassCustomSerializer()
    obj.number = tonumber(string.trim(data.custom_number, "abcdef"))
    return obj
end

local function test()
    local c = TestClass()
    c.string = "changed"
    c.nested_table.string = "changed_nested"

    local test_payload = {
        ctype_vec3 = vec3(1, 2, 3),
        string = "abc",
        number = 123,
        boolean = true,
        nil_value = nil,
        simple_table = {
            number = 1,
            string = '2'
        },
        array = { "a", "b" },
        class = c,
        class_custom_serializer = TestClassCustomSerializer()
    }

    local serialized = Serializer.serialize(test_payload)
    local deserialized = Serializer.deserialize(serialized)

    ---@diagnostic disable: undefined-field
    local res, obj_a, obj_b = Serializer.checkEqual("test_payload", test_payload, deserialized, false)
    Assert.True(res, "Serialization faled at: `" .. tostring(obj_a) .. "` vs. `" .. tostring(obj_b) .. "`\n")
end

test()

return Serializer
