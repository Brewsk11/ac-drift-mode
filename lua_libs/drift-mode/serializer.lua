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

    -- custom classes
    if type(data) == "table" and data.serialize ~= nil then
        return data:serialize()
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

    -- custom classes
    if data['__class'] ~= nil then
        Assert.NotEqual(_G[data.__class], nil, "Deserializing class that is not in global namespace (_G[classname])")
        return _G[data.__class].deserialize(data)
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

local function test()
    local test_payload = {
        a = vec3(1, 2, 3),
        b = "abc",
        c = 123,
        d = true,
        e = nil,
        f = {
            a = 1,
            b = '2'
        },
        g = { "a", "b" }
    }

    local serialized = Serializer.serialize(test_payload)
    local deserialized = Serializer.deserialize(serialized)

    local test_item = function (a, b)
        assert(a == b, "Serializing test failed: " .. tostring(a) .. ' vs. ' .. tostring(b))
    end

    ---@diagnostic disable: undefined-field
    test_item(test_payload.a, deserialized.a)
    test_item(test_payload.b, deserialized.b)
    test_item(test_payload.c, deserialized.c)
    test_item(test_payload.d, deserialized.d)
    test_item(test_payload.e, deserialized.e)
    test_item(test_payload.f.a, deserialized.f.a)
    test_item(test_payload.f.b, deserialized.f.b)
    test_item(test_payload.g[1], deserialized.g[1])
    test_item(test_payload.g[2], deserialized.g[2])
end

test()

return Serializer
