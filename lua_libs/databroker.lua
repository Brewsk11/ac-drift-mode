local json = require('drift-mode/json')

local DataBroker = {}
local Namespace = "driftmode__"

function DataBroker.serialize(data)

    -- table
    if type(data) == 'table' then
        local new_data = { __table = true }
        for el, val in pairs(data) do
            new_data[el] = DataBroker.serialize(val)
        end
        return new_data
    end

    -- vec3
    if type(data) == 'cdata' and data.x ~= nil and data.y ~= nil and data.z ~= nil then
        return {
            __vector = true,
            x = data.x,
            y = data.y,
            z = data.z
        }
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

function DataBroker.deserialize(data)

    -- table
    if data['__table'] ~= nil then
        local new_data = {}
        for el, val in pairs(data) do
            if not string.startsWith(el, '__') then
                new_data[el] = DataBroker.deserialize(val)
            end
        end
        return new_data
    end

    -- vec3
    if data['__vector'] ~= nil then
        return vec3(data.x, data.y, data.z)
    end

    return data.__val
end

function DataBroker.store(name, data)
    local serialized_data = DataBroker.serialize(data)
    local json_repr = json.encode(serialized_data)

    ac.store(Namespace .. name, json_repr)
end

function DataBroker.read(name)
    local data = DataBroker.readRaw(name)
    return DataBroker.deserialize(data)
end

function DataBroker.readRaw(name)
    local json_repr = ac.load(Namespace .. name)
    if json_repr == nil then
        return nil
    end

    return json.decode(json_repr)
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

    local serialized = DataBroker.serialize(test_payload)
    local deserialized = DataBroker.deserialize(serialized)

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

return DataBroker