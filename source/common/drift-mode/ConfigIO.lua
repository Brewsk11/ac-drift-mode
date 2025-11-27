local Serializer = require('drift-mode.Serializer')
local Resources = require("drift-mode.Resources")

local json = require('drift-mode.json')

local TrackConfigInfo = require("drift-mode.models.Elements.Course.TrackConfigInfo")


local ConfigIO = {}

local usr_cfg_path = ac.getFolder(ac.FolderID.ExtCfgUser) .. "\\drift-mode"
local sys_cfg_path = ac.getFolder(ac.FolderID.ExtCfgSys) .. "\\drift-mode"

local track_id = ac.getTrackID()

local usr_track_config_dir = usr_cfg_path .. "\\tracks\\" .. track_id
local sys_track_config_dir = sys_cfg_path .. "\\tracks\\" .. track_id

local last_used_name = ".last.json"
local last_used_track_config_path = usr_track_config_dir .. "\\" .. last_used_name

local car_id = ac.getCarID(0)

local usr_car_config_dir = usr_cfg_path .. "\\cars"
local sys_car_config_dir = sys_cfg_path .. "\\cars"

---@return CarConfig?
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

function ConfigIO.carConfigExists()
    local car_config = ConfigIO.loadCarConfig()
    if car_config == nil then
        return false
    else
        return true
    end
end

function ConfigIO.saveCarConfig(car_data)
    io.createDir(usr_car_config_dir)
    ConfigIO.saveConfig(usr_car_config_dir .. "\\" .. car_id .. '.json', car_data)
end

---@return TrackConfigInfo|nil
function ConfigIO.getLastUsedTrackConfigInfo()
    if io.fileExists(last_used_track_config_path) then
        return ConfigIO.loadConfig(last_used_track_config_path)
    end
    return nil
end

function ConfigIO.setLastUsedTrackConfigInfo(track_cfg_info)
    io.createDir(usr_track_config_dir)
    ConfigIO.saveConfig(last_used_track_config_path, track_cfg_info)
end

function ConfigIO.getUserCoursesDirectory()
    return usr_track_config_dir
end

---@return TrackConfigInfo[]
function ConfigIO.listTrackConfigs()
    local usr_configs = io.scanDir(usr_track_config_dir)
    local sys_configs = io.scanDir(sys_track_config_dir)
    local track_configs = {}

    for _, cfg_name in ipairs(usr_configs) do
        if cfg_name ~= last_used_name then
            track_configs[#track_configs + 1] = TrackConfigInfo(
                cfg_name:gsub(".json", ""),
                usr_track_config_dir .. "\\" .. cfg_name,
                TrackConfigType.User
            )
        end
    end

    for _, cfg_name in ipairs(sys_configs) do
        track_configs[#track_configs + 1] = TrackConfigInfo(
            cfg_name:gsub(".json", ""),
            sys_track_config_dir .. "\\" .. cfg_name,
            TrackConfigType.Official
        )
    end

    return track_configs
end

---@param track_config TrackConfig
---@return TrackConfigInfo
function ConfigIO.saveTrackConfig(track_config)
    io.createDir(usr_track_config_dir)
    local track_cfg_info = TrackConfigInfo(
        track_config.name,
        usr_track_config_dir .. "\\" .. track_config.name .. '.json',
        TrackConfigType.User
    )

    track_config.__version = Resources.Version

    ConfigIO.saveConfig(track_cfg_info.path, track_config)
    ConfigIO.setLastUsedTrackConfigInfo(track_cfg_info)
    return track_cfg_info
end

---comment
---@param track_cfg_info TrackConfigInfo
---@return unknown|nil
function ConfigIO.loadTrackConfig(track_cfg_info)
    ConfigIO.setLastUsedTrackConfigInfo(track_cfg_info)
    return ConfigIO.loadConfig(track_cfg_info.path)
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
    local file = assert(io.open(path, 'w+b'), 'Error loading file: ' .. path)

    local serialized = Serializer.serialize(data)
    local json_content = json.encode(serialized)

    file:write(json_content)
    file:close()
end

return ConfigIO
