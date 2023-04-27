local Serializer = require('drift-mode/serializer')
local json = require('drift-mode/json')

local ConfigIO = {}

local usr_cfg_path = ac.getFolder(ac.FolderID.ExtCfgUser)  .. "\\drift-mode"
local sys_cfg_path = ac.getFolder(ac.FolderID.ExtCfgSys) .. "\\drift-mode"

local track_id = ac.getTrackID()

local usr_track_config_dir = usr_cfg_path .. "\\tracks\\" .. track_id
local sys_track_config_dir = sys_cfg_path .. "\\tracks\\" .. track_id

function ConfigIO.listTrackConfigs()
    local usr_configs = io.scanDir(usr_cfg_path .. "\\tracks\\" .. track_id)
    local sys_configs = io.scanDir(sys_cfg_path .. "\\tracks\\" .. track_id)
    local track_configs = {
        user_configs = {},
        official_configs = {}
    }
    for _, cfg_name in ipairs(usr_configs) do track_configs.user_configs[#track_configs.user_configs+1] = cfg_name end
    for _, cfg_name in ipairs(sys_configs) do track_configs.official_configs[#track_configs.official_configs+1] = cfg_name end
    return track_configs
end

---@param track_config TrackConfig
function ConfigIO.saveTrackConfig(track_config)
    io.createDir(usr_track_config_dir)
    ConfigIO.saveConfig(usr_track_config_dir .. "\\" .. track_config.name, track_config)
end

function ConfigIO.loadTrackConfig(name, dir)
    if dir == "official" then
        return ConfigIO.loadConfig(sys_track_config_dir .. "\\" .. name)
    else
        return ConfigIO.loadConfig(usr_track_config_dir .. "\\" .. name)
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
