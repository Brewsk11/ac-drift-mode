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
        scale_factor = track_map_ini_config:get("PARAMETERS", "SCALE_FACTOR", 1),
        size_img = ui.imageSize(self._track_map_image_path)
    }

    self._viewport_size = viewport_size or vec2(100, 100)

    self._bounding_box = bounding_box
    self._padding = 50

    -- Initialize cache fields
    self._dirty = true
    self._cached_scale = nil
    self._cached_scaled_size = nil
    self._cached_offset = nil
end

---@return vec2
function MinimapHelper:getViewportSize()
    return self._viewport_size
end

---@param viewport_size vec2
function MinimapHelper:setViewportSize(viewport_size)
    self._viewport_size = viewport_size
    self._dirty = true
end

---@return table
function MinimapHelper:getBoundingBox()
    return self._bounding_box
end

---@param bounding_box table
function MinimapHelper:setBoundingBox(bounding_box)
    self._bounding_box = bounding_box
    self._dirty = true
end

---@return number
function MinimapHelper:getPadding()
    return self._padding
end

---@param padding number
function MinimapHelper:setPadding(padding)
    self._padding = padding
    self._dirty = true
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
function MinimapHelper:recalculateMapScalingAndOffset()
    local bounding_box_p1 = nil
    local bounding_box_p2 = nil
    if self:getBoundingBox() then
        bounding_box_p1 = self:worldToMap(self:getBoundingBox().p1) - vec2(self:getPadding(), self:getPadding())
        bounding_box_p2 = self:worldToMap(self:getBoundingBox().p2) + vec2(self:getPadding(), self:getPadding())
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
        self:getViewportSize().x / bb_box:getWidth(),
        self:getViewportSize().y / bb_box:getHeight()
    )

    -- Calculate scaled dimensions of the original image
    local scaled_width = self._track_map_data.size.x / self._track_map_data.scale_factor * scale
    local scaled_height = self._track_map_data.size.y / self._track_map_data.scale_factor * scale
    local scaled_size = self._track_map_data.size_img * scale -- vec2(scaled_width, scaled_height)

    -- Calculate the center of the bounding box
    local scaled_bbox_center_x = (bounding_box_p1.x + bounding_box_p2.x) / 2 * scale
    local scaled_bbox_center_y = (bounding_box_p1.y + bounding_box_p2.y) / 2 * scale

    local desired_offset_x = scaled_bbox_center_x - self:getViewportSize().x / 2
    local desired_offset_y = scaled_bbox_center_y - self:getViewportSize().y / 2
    local offset = vec2(desired_offset_x, desired_offset_y)

    self._cached_scale = scale
    self._cached_scaled_size = scaled_size
    self._cached_offset = offset
end

--- Calculates the scaled bounding box and offset for drawing the map
---@private
---@param force_recalculate boolean|nil
---@return number, vec2, vec2
function MinimapHelper:getMapScalingAndOffset(force_recalculate)
    if force_recalculate or self._dirty then
        self:recalculateMapScalingAndOffset()
        self._dirty = false
    end

    ac.debug("cached_scale", self._cached_scale)
    return self._cached_scale, self._cached_scaled_size, self._cached_offset
end

function MinimapHelper:drawMap(origin)
    local _, scaled_size, offset = self:getMapScalingAndOffset()

    ui.drawImage(
        self._track_map_image_path,
        origin - offset,
        origin + scaled_size - offset,
        rgbm(1, 1, 1, 0.3)
    )
end

---@param coord Point
---@return vec2
function MinimapHelper:mapCoord(coord)
    local scale, _, offset = self:getMapScalingAndOffset()

    local map_coord = self:worldToMap(coord) * scale - offset
    return map_coord
end

function MinimapHelper:drawBoundingBox(origin)
    if self:getBoundingBox() == nil then return end

    ui.drawRect(
        origin + self:mapCoord(self:getBoundingBox().p1),
        origin + self:mapCoord(self:getBoundingBox().p2),
        rgbm.colors.green
    )
end

---@param origin vec2
---@param idx integer
---@param car_config CarConfig?
function MinimapHelper:drawCar(origin, idx, car_config)
    local car = ac.getCar(idx)

    if car_config ~= nil then
        local p1, p2, p3, p4 =
            car.position + car.look * car_config.frontOffset + car.side * car_config.frontSpan,
            car.position + car.look * car_config.frontOffset - car.side * car_config.frontSpan,
            car.position - car.look * car_config.rearOffset + car.side * car_config.rearSpan,
            car.position - car.look * car_config.rearOffset - car.side * car_config.rearSpan

        ui.drawQuadFilled(
            self:mapCoord(Point(p1)),
            self:mapCoord(Point(p2)),
            self:mapCoord(Point(p4)),
            self:mapCoord(Point(p3)),
            rgbm.colors.gray)
    end
end

---@param track_config TrackConfig
function MinimapHelper:drawTrackConfig(origin, track_config)
    for _, obj in ipairs(track_config.scoringObjects) do
        obj:drawFlat(function(p)
            return origin + self:mapCoord(p)
        end)
    end
end

---@param scoring_objects_states ScoringObjectState[]?
function MinimapHelper:drawRunState(origin, scoring_objects_states)
    if scoring_objects_states == nil then
        return
    end
    for _, obj in ipairs(scoring_objects_states) do
        obj:drawFlat(function(p)
            return origin + self:mapCoord(p)
        end)
    end
end

local function test()
end

test()

return MinimapHelper
