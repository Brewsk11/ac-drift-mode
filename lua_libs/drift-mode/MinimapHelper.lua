local Assert = require('drift-mode/assert')

---@class MinimapHelper
local MinimapHelper = class("MinimapHelper")

---@param track_content_path string
---@param max_size vec2
function MinimapHelper:initialize(track_content_path, max_size)
    self._track_map_image_path = track_content_path .. "/map.png"

    local track_map_data_path = track_content_path .. "/data/map.ini"
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
    self.viewport_size = max_size
end

---Maps a world coordinate to a pixel position on map.png
---@param coord Point
---@private
---@return vec2
function MinimapHelper:worldToMap(coord)
    -- The transformation from world coordinate (eg. ac.getCar(0).position) to a coordinate on the map.png is:
    -- 1. Add offset from the map.ini file to the coordinate
    -- 2. Inversly scale the coorinate by SCALE_FACTOR from the map.ini. This is the scale that map creator set
    --    and is intrinsically bound to the map.png, thus, it is probably not useful anythere else.
    -- The above means both transformations can be done in one functions, and it is probably not useful
    -- to split these functions.
    local map_pos = (coord:flat() + self._track_map_data.offset) / self._track_map_data.scale_factor

    return map_pos
end

function MinimapHelper:drawMap(origin, bounding_box)
    self.bounding_box = bounding_box

    local bounding_box_p1 = self:worldToMap(bounding_box.p1)
    local bounding_box_p2 = self:worldToMap(bounding_box.p2)

    local bb_box = Box2D(bounding_box_p1, bounding_box_p2)

    -- Compute scale to fit the bounding box into the viewport
    local scale = math.min(
        self.viewport_size.x / bb_box:getWidth(),
        self.viewport_size.y / bb_box:getHeight()
    )

    -- Calculate scaled dimensions of the original image
    local scaled_width = self._track_map_data.size.x * self._track_map_data.scale_factor * scale
    local scaled_height = self._track_map_data.size.y * self._track_map_data.scale_factor * scale

    -- Calculate the center of the bounding box
    local scaled_bbox_center_x = (bounding_box_p1.x + bounding_box_p2.x) / 2 * scale
    local scaled_bbox_center_y = (bounding_box_p1.y + bounding_box_p2.y) / 2 * scale

    local desired_offset_x = scaled_bbox_center_x - self.viewport_size.x / 2
    local desired_offset_y = scaled_bbox_center_y - self.viewport_size.y / 2

    local desired_offset = vec2(desired_offset_x, desired_offset_y)

    ui.drawImage(
        self._track_map_image_path,
        origin - desired_offset,
        origin + vec2(scaled_width, scaled_height) - desired_offset,
        rgbm(1, 1, 1, 1)
    )
end

function MinimapHelper:mapCoord(coord)
    if self.bounding_box == nil then return end

    local map_coord = self:worldToMap(coord)

    local bounding_box_p1 = self:worldToMap(self.bounding_box.p1)
    local bounding_box_p2 = self:worldToMap(self.bounding_box.p2)

    local bb_box = Box2D(bounding_box_p1, bounding_box_p2)

    -- Compute scale to fit the bounding box into the viewport
    local scale = math.min(
        self.viewport_size.x / bb_box:getWidth(),
        self.viewport_size.y / bb_box:getHeight()
    )

    -- Calculate scaled dimensions of the original image
    local scaled_width = self._track_map_data.size.x * self._track_map_data.scale_factor * scale
    local scaled_height = self._track_map_data.size.y * self._track_map_data.scale_factor * scale

    -- Calculate the center of the bounding box
    local scaled_bbox_center_x = (bounding_box_p1.x + bounding_box_p2.x) / 2 * scale
    local scaled_bbox_center_y = (bounding_box_p1.y + bounding_box_p2.y) / 2 * scale
    local scaled_bbox_center = vec2(scaled_bbox_center_x, scaled_bbox_center_y)

    local coord_scaled = map_coord * scale

    local desired_offset_x = scaled_bbox_center_x - self.viewport_size.x / 2
    local desired_offset_y = scaled_bbox_center_y - self.viewport_size.y / 2

    local desired_offset = vec2(desired_offset_x, desired_offset_y)

    return coord_scaled - desired_offset
end

function MinimapHelper:drawBoundingBox(origin)
end

function MinimapHelper:drawCar(origin, idx)
    local car_position = ac.getCar(idx).position
    ui.drawCircleFilled(self:mapCoord(Point(car_position)), 2, rgbm.colors.green)
end

---@param track_config TrackConfig
function MinimapHelper:drawTrackConfig(origin, track_config)
    if self.bounding_box ~= nil then
        -- ui.drawCircleFilled(
        --     self:mapCoord(Point((self.bounding_box.p1:value() + self.bounding_box.p2:value()) / 2)), 2,
        --     rgbm.colors.green
        -- )

        for _, obj in ipairs(track_config.scoringObjects) do
            obj:drawFlat(function(p)
                return self:mapCoord(p)
            end)
        end
    end
end

local function test()

end

test()

return MinimapHelper
