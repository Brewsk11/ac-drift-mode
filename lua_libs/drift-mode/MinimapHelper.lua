local Assert = require('drift-mode/assert')

---@class MinimapHelper
---@field private track_content_path string
local MinimapHelper = class("MinimapHelper")

function MinimapHelper:initialize(track_content_path)
    self.track_content_path = track_content_path
    self.track_map_image_path = self.track_content_path .. "/map.png"
    self.track_map_data_path = self.track_content_path .. "/data/map.ini"
    self.track_map_data_ini = ac.INIConfig.load(self.track_map_data_path)
    self.track_map_data = {
        offset = vec2(
            self.track_map_data_ini:get('PARAMETERS', 'X_OFFSET', 0),
            self.track_map_data_ini:get('PARAMETERS', 'Z_OFFSET', 0)),
        size = vec2(
            self.track_map_data_ini:get('PARAMETERS', 'WIDTH', 1),
            self.track_map_data_ini:get('PARAMETERS', 'HEIGHT', 1)),
        scale_factor = self.track_map_data_ini:get("PARAMETERS", "SCALE_FACTOR", 1)
    }
    self.scale = 1
    self.bounding_box = { p1 = nil, p2 = nil }
end

--- Maps a world coordinate to a pixel position on map.png
---@param coord Point
function MinimapHelper:worldToMap(coord)
    return (coord:flat() + self.track_map_data.offset) / self.track_map_data.scale_factor
end

function MinimapHelper:worldToScaledMap(coord)
    return self:worldToMap(coord) * self:getScale()
end

function MinimapHelper:worldToScaledMapTransformer()
    return (function(coord)
        return self:worldToScaledMap(coord)
    end)
end

function MinimapHelper:worldToScaledBoundMap(coord)
    Assert.Equal(self:isBound(), true, "called worldToScaledBoundMap on unbound map")

    local point_on_scaled_map = self:worldToScaledMap(coord)
    local bounding_p1_on_scaled_map = self:worldToScaledMap(self.bounding_box.p1)
    local bounding_p2_on_scaled_map = self:worldToScaledMap(self.bounding_box.p2)

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

function MinimapHelper:worldToScaledBoundMapTransformer()
    return (function(coord)
        local res = self:worldToScaledBoundMap(coord)
        return res
    end)
end

function MinimapHelper:setScale(scale)
    self.scale = scale
end

--- Proportional
function MinimapHelper:setWidth(new_width)
    local original_width = self.track_map_data.size.x
    local scale_factor = new_width / original_width
    self:setScale(scale_factor)
end

--- Proportional
function MinimapHelper:setHeight(new_height)
    local original_width = self.track_map_data.size.y
    local scale_factor = new_height / original_width
    self:setScale(scale_factor)
end

function MinimapHelper:getScale()
    return self.scale
end

function MinimapHelper:getSize()
    return self.track_map_data.size * self.scale
end

function MinimapHelper:setBoundingBox(bounding_box)
    self.bounding_box = bounding_box

    self.uv1 = self:worldToScaledMap(bounding_box.p1):div(self:getSize())
    self.uv2 = self:worldToScaledMap(bounding_box.p2):div(self:getSize())
end

function MinimapHelper:isBound()
    return self.bounding_box.p1 ~= nil
end

return MinimapHelper
