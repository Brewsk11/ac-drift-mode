local Serializer = {}

function Serializer.serialize(data)

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

function Serializer.deserialize(data)
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
        }
    }

    local serialized = Serializer.serialize(test_payload)
    local deserialized = Serializer.deserialize(serialized)

    local test = function (a, b)
        assert(a == b, "Serializing test failed: " .. tostring(a) .. ' vs. ' .. tostring(b))
    end

    test(test_payload.a, deserialized.a)
    test(test_payload.b, deserialized.b)
    test(test_payload.c, deserialized.c)
    test(test_payload.d, deserialized.d)
    test(test_payload.e, deserialized.e)
    test(test_payload.f.a, deserialized.f.a)
    test(test_payload.f.b, deserialized.f.b)
end

test()

return Serializer
