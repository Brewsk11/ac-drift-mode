local Serializer = require('drift-mode/serializer')
local json = require('drift-mode/json')

local ConfigIO = {}

local usr_cfg_path = ac.getFolder(ac.FolderID.ExtCfgUser)  .. "\\drift-mode"
local sys_cfg_path = ac.getFolder(ac.FolderID.ExtCfgSys) .. "\\drift-mode"

local track_id = ac.getTrackID()

local usr_track_config_dir = usr_cfg_path .. "\\tracks\\" .. track_id
local sys_track_config_dir = sys_cfg_path .. "\\tracks\\" .. track_id

local car_id = ac.getCarID(0)

local usr_car_config_dir = usr_cfg_path .. "\\cars"
local sys_car_config_dir = sys_cfg_path .. "\\cars"

function ConfigIO.loadCarConfig()
    local usr_car_cfg_path = usr_car_config_dir .. "\\" .. car_id .. '.json'
    local sys_car_cfg_path = sys_car_config_dir .. "\\" .. car_id .. '.json'

    if io.fileExists(usr_car_cfg_path) then
        return ConfigIO.loadConfig(usr_car_cfg_path)
    end

    if io.fileExists(sys_car_cfg_path) then
        return ConfigIO.loadConfig(sys_car_cfg_path)
    end

    return nil
end

function ConfigIO.saveCarConfig(car_data)
    io.createDir(usr_car_config_dir)
    ConfigIO.saveConfig(usr_car_config_dir .. "\\" .. car_id  .. '.json', car_data)
end

function ConfigIO.listTrackConfigs()
    local usr_configs = io.scanDir(usr_track_config_dir)
    local sys_configs = io.scanDir(sys_track_config_dir)
    local track_configs = {
        user_configs = {},
        official_configs = {}
    }
    for _, cfg_name in ipairs(usr_configs) do track_configs.user_configs[#track_configs.user_configs+1] = cfg_name:gsub(".json", "") end
    for _, cfg_name in ipairs(sys_configs) do track_configs.official_configs[#track_configs.official_configs+1] = cfg_name:gsub(".json", "") end
    return track_configs
end

---@param track_config TrackConfig
function ConfigIO.saveTrackConfig(track_config)
    io.createDir(usr_track_config_dir)
    ConfigIO.saveConfig(usr_track_config_dir .. "\\" .. track_config.name .. '.json', track_config)
end

function ConfigIO.loadTrackConfig(name, dir)
    if dir == "official" then
        return ConfigIO.loadConfig(sys_track_config_dir .. "\\" .. name .. '.json')
    else
        return ConfigIO.loadConfig(usr_track_config_dir .. "\\" .. name .. '.json')
    end
end

function ConfigIO.loadConfig(path)
    assert(type(path) == 'string', 'Parameter "fileName" must be a string.')
    if not io.exists(path) then
        return nil
    end

	local file = io.open(path, 'r')
	local file_content = file:read("a")
    file:close()

    local json_repr = json.decode(file_content)
    local deserialized = Serializer.deserialize(json_repr)

	return deserialized
end

function ConfigIO.saveConfig(path, data)
    assert(type(path) == 'string', 'Parameter "fileName" must be a string.')
	local file = assert(io.open(path, 'w+b'), 'Error loading file :' .. path)

    local serialized = Serializer.serialize(data)
    local json_content = json.encode(serialized)

	file:write(json_content)
	file:close()
end

return ConfigIO
