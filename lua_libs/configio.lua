local Serializer = require('drift-mode/serializer')
local json = require('drift-mode/json')

local ConfigIO = {}

function ConfigIO.loadConfig(path)
    assert(type(path) == 'string', 'Parameter "fileName" must be a string.')
    if not io.exists(path) then
        return nil
    end

	local file = io.open(path, 'r')
	local file_content = file:read("a")
    file:close()

    ac.debug("file_content", file_content)
    local json_repr = json.decode(file_content)
    local deserialized = Serializer.deserialize(json_repr)

    ac.debug("json_repr", deserialized)
	return deserialized
end

function ConfigIO.saveConfig(path, data)
    assert(type(path) == 'string', 'Parameter "fileName" must be a string.')
	assert(type(data) == 'table', 'Parameter "data" must be a table.')
	local file = assert(io.open(path, 'w+b'), 'Error loading file :' .. path)

    local serialized = Serializer.serialize(data)
    local json_content = json.encode(serialized)

	file:write(json_content)
	file:close()
end

function ConfigIO.updateConfig(path, new_data)
	local data = ConfigIO.loadConfig(path)

    for k, v in pairs(new_data) do
        data[k] = v
    end

    ConfigIO.saveConfig(path, data)
end

return ConfigIO
