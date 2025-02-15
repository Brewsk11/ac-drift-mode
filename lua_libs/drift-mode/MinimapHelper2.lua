local Assert = require('drift-mode/assert')

---@class MinimapHelper2
local MinimapHelper2 = class("MinimapHelper2")

---@param track_content_path string
---@param max_size vec2
function MinimapHelper2:initialize(track_content_path, max_size)
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

    self.uv = { vec2(0, 0), vec2(1, 1) }
    self:setMaxsize(max_size)
end

function MinimapHelper2:setMaxsize(max_size)
    self.max_size = max_size
    self:recalculateUV()
end

function MinimapHelper2:getMaxsize()
    return self.max_size
end

function MinimapHelper2:recalculateUV()
    local mapbb = Box2D(vec2(0, 0), self._track_map_data.size)
    mapbb:fitInAndMoveTo(Box2D(vec2(0, 0), self:getMaxsize()))

    self.uv = {
        vec2(
            (1 - self:getMaxsize().x / mapbb:getWidth()) / 2,
            (1 - self:getMaxsize().y / mapbb:getHeight()) / 2
        ),
        vec2(
            (self:getMaxsize().x / mapbb:getWidth() - 1) / 2 + 1,
            (self:getMaxsize().y / mapbb:getHeight() - 1) / 2 + 1
        )
    }
end

function MinimapHelper2:setBoundingBox(bounding_box)

end

function MinimapHelper2:drawMap(origin)
    ui.drawImage(
        self._track_map_image_path,
        origin,
        origin + self:getMaxsize(),
        self.uv[1],
        self.uv[2]
    )

    ui.drawRect(
        origin + self:getMaxsize() * self.uv[1],
        origin + self:getMaxsize() * self.uv[2],
        rgbm(1, 0, 0, 1)
    )
end

function MinimapHelper2:drawBoundingBox(origin)
end

---@param track_config TrackConfig
function MinimapHelper2:drawTrackConfig(track_config)
end

local function test()

end

test()

return MinimapHelper2
