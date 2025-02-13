local Assert = require('drift-mode/assert')

---@class MinimapHelper
---@field private _track_map_data table Data from map ini file required for coordinate calculation
---@field private _track_content_path string
---@field private _track_map_image_path string Path to the track minimap
---@field private _scale number The minimap scale, should be changed with the setter
---@field public bounding_box nil|table World coordinate corners of the area which the minimap should show. Nil is the whole map.
---@field public max_size vec2 The size of the container the minimap is to be rendered in.
local MinimapHelper = class("MinimapHelper")

---@param track_content_path string
---@param max_size vec2
function MinimapHelper:initialize(track_content_path, max_size)
    self._track_content_path = track_content_path
    self._track_map_image_path = self._track_content_path .. "/map.png"

    local track_map_data_path = self._track_content_path .. "/data/map.ini"
    local track_map_ini_config = ac.INIConfig.load(track_map_data_path)

    self._track_map_data = {
        offset = vec2(
            track_map_ini_config:get('PARAMETERS', 'X_OFFSET', 0),
            track_map_ini_config:get('PARAMETERS', 'Z_OFFSET', 0)
        ),
        size = vec2(
            track_map_ini_config:get('PARAMETERS', 'WIDTH', 1),
            track_map_ini_config:get('PARAMETERS', 'HEIGHT', 1)
        ),
        scale_factor = track_map_ini_config:get("PARAMETERS", "SCALE_FACTOR", 1)
    }

    self._scale = 1
    self.bounding_box = nil

    self.max_size = max_size
end

---Maps a world coordinate to a pixel position on map.png
---@param coord Point
---@private
function MinimapHelper:worldToRawMap(coord)
    -- The transformation from world coordinate (eg. ac.getCar(0).position) to a coordinate on the map.png is:
    -- 1. Add offset from the map.ini file to the coordinate
    -- 2. Inversly scale the coorinate by SCALE_FACTOR from the map.ini. This is the scale that map creator set
    --    and is intrinsically bound to the map.png, thus, it is probably not useful anythere else.
    -- The above means both transformations can be done in one functions, and it is probably not useful
    -- to split these functions.
    local map_pos = (coord:flat() + self._track_map_data.offset) / self._track_map_data.scale_factor

    return map_pos
end

---Maps a world coordinate to a pixel position on map.png additionally scaled by the user-provided
---scale, to be correctly scaled in the UI.
---@param coord any
function MinimapHelper:worldToMap(coord)
    return self:worldToRawMap(coord) * self:getScale()
end

function MinimapHelper:worldToMapTransformer()
    return (function(coord)
        return self:worldToMap(coord)
    end)
end

function MinimapHelper:worldToBoundMap(coord)
    Assert.Equal(self:isBound(), true, "called worldToBoundMap on unbound map")

    local point_on_scaled_map = self:worldToMap(coord)
    local bounding_p1_on_scaled_map = self:worldToMap(self.bounding_box.p1)
    local bounding_p2_on_scaled_map = self:worldToMap(self.bounding_box.p2)

    if point_on_scaled_map.x < bounding_p1_on_scaled_map.x or
        point_on_scaled_map.x > bounding_p2_on_scaled_map.x or
        point_on_scaled_map.y < bounding_p1_on_scaled_map.y or
        point_on_scaled_map.y > bounding_p2_on_scaled_map.y then
        return nil -- Point outside of the bounding box
    end

    local bounding_size_on_scaled_map = vec2(
        bounding_p2_on_scaled_map.x - bounding_p1_on_scaled_map.x,
        bounding_p2_on_scaled_map.y - bounding_p1_on_scaled_map.y
    )

    local p1 = ((point_on_scaled_map.x - bounding_p1_on_scaled_map.x) / bounding_size_on_scaled_map.x * self:getSize().x)
    local p2 = ((point_on_scaled_map.y - bounding_p1_on_scaled_map.y) / bounding_size_on_scaled_map.y * self:getSize().y)

    return vec2(p1, p2)
end

function MinimapHelper:worldToBoundMapTransformer()
    return (function(coord)
        local res = self:worldToBoundMap(coord)
        return res
    end)
end

function MinimapHelper:setScale(scale)
    self._scale = scale
end

--- Proportional
function MinimapHelper:setWidth(new_width)
    local original_width = self._track_map_data.size.x
    local scale_factor = new_width / original_width
    self:setScale(scale_factor)
end

--- Proportional
function MinimapHelper:setHeight(new_height)
    local original_width = self._track_map_data.size.y
    local scale_factor = new_height / original_width
    self:setScale(scale_factor)
end

function MinimapHelper:getScale()
    return self._scale
end

function MinimapHelper:getSize()
    return self._track_map_data.size * self._scale
end

function MinimapHelper:setBoundingBox(bounding_box)
    self.bounding_box = bounding_box

    self.uv1 = self:worldToMap(bounding_box.p1):div(self:getSize())
    self.uv2 = self:worldToMap(bounding_box.p2):div(self:getSize())
end

function MinimapHelper:isBound()
    return self.bounding_box ~= nil
end

return MinimapHelper
