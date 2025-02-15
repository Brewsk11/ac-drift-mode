local Assert = require('drift-mode/assert')

---@class MinimapHelper
local MinimapHelper = class("MinimapHelper")

---@param track_content_path string
---@param viewport_size vec2
function MinimapHelper:initialize(track_content_path, viewport_size, bounding_box)
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

    self.viewport_size = viewport_size or vec2(100, 100)

    self.bounding_box = bounding_box
    self.padding = 10
end

--- Maps a world coordinate to a pixel position on map.png
---@param coord Point
---@private
---@return vec2
function MinimapHelper:worldToMap(coord)
    return (coord:flat() + self._track_map_data.offset) / self._track_map_data.scale_factor
end

--- Calculates the scaled bounding box and offset for drawing the map
---@private
---@return number, vec2, vec2
function MinimapHelper:getMapScalingAndOffset()
    local bounding_box_p1 = nil
    local bounding_box_p2 = nil
    if self.bounding_box then
        bounding_box_p1 = self:worldToMap(self.bounding_box.p1) - vec2(self.padding, self.padding)
        bounding_box_p2 = self:worldToMap(self.bounding_box.p2) + vec2(self.padding, self.padding)
    else
        bounding_box_p1 = vec2(0, 0)
        bounding_box_p2 = vec2(
            self._track_map_data.size.x * self._track_map_data.scale_factor,
            self._track_map_data.size.y * self._track_map_data.scale_factor
        )
    end

    local bb_box = Box2D(bounding_box_p1, bounding_box_p2)

    -- Compute scale to fit the bounding box into the viewport
    local scale = math.min(
        self.viewport_size.x / bb_box:getWidth(),
        self.viewport_size.y / bb_box:getHeight()
    )

    -- Calculate scaled dimensions of the original image
    local scaled_width = self._track_map_data.size.x * self._track_map_data.scale_factor * scale
    local scaled_height = self._track_map_data.size.y * self._track_map_data.scale_factor * scale
    local scaled_size = vec2(scaled_width, scaled_height)

    -- Calculate the center of the bounding box
    local scaled_bbox_center_x = (bounding_box_p1.x + bounding_box_p2.x) / 2 * scale
    local scaled_bbox_center_y = (bounding_box_p1.y + bounding_box_p2.y) / 2 * scale

    local desired_offset_x = scaled_bbox_center_x - self.viewport_size.x / 2
    local desired_offset_y = scaled_bbox_center_y - self.viewport_size.y / 2
    local offset = vec2(desired_offset_x, desired_offset_y)

    return scale, scaled_size, offset
end

function MinimapHelper:drawMap(origin)
    local _, scaled_size, offset = self:getMapScalingAndOffset()

    ui.drawImage(
        self._track_map_image_path,
        origin - offset,
        origin + scaled_size - offset,
        rgbm(1, 1, 1, 1)
    )
end

function MinimapHelper:mapCoord(coord)
    local scale, _, offset = self:getMapScalingAndOffset()

    local map_coord = self:worldToMap(coord) * scale - offset
    return map_coord
end

function MinimapHelper:drawBoundingBox(origin)
    ui.drawRect(
        origin + self:mapCoord(self.bounding_box.p1),
        origin + self:mapCoord(self.bounding_box.p2),
        rgbm.colors.green
    )
end

function MinimapHelper:drawCar(origin, idx)
    local car_position = ac.getCar(idx).position
    ui.drawCircleFilled(self:mapCoord(Point(car_position)), 2, rgbm.colors.green)
end

---@param track_config TrackConfig
function MinimapHelper:drawTrackConfig(origin, track_config)
    for _, obj in ipairs(track_config.scoringObjects) do
        obj:drawFlat(function(p)
            return self:mapCoord(p)
        end)
    end
end

local function test()
end

test()

return MinimapHelper
