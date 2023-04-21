local json = require('drift-mode/json')
local Serializer = require('drift-mode/serializer')

local DataBroker = {}
local Namespace = "driftmode__"

function DataBroker.store(name, data)
    local serialized_data = Serializer.serialize(data)
    local json_repr = json.encode(serialized_data)

    ac.store(Namespace .. name, json_repr)
end

function DataBroker.read(name)
    local data = DataBroker.readRaw(name)
    return Serializer.deserialize(data)
end

function DataBroker.readRaw(name)
    local json_repr = ac.load(Namespace .. name)
    if json_repr == nil then
        return nil
    end

    return json.decode(json_repr)
end
