local map_image_path = ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/map.png"
local map_ini_path = ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/data/map.ini"
local map_data = ac.INIConfig.load(map_ini_path)

local map_info = {
    offset = vec2(
        map_data:get('PARAMETERS', 'X_OFFSET', 0),
        map_data:get('PARAMETERS', 'Z_OFFSET', 0)),
    size = vec2(
        map_data:get('PARAMETERS', 'WIDTH', 1),
        map_data:get('PARAMETERS', 'HEIGHT', 1)),
    scale = map_data:get("PARAMETERS", "SCALE_FACTOR", 1)
}

--local extra_canvas = ui.ExtraCanvas(vec2(512, 512)):clear(rgbm(0, 0, 0, 0)):setName("Testing")

local map_horizontal = map_info.size.x > map_info.size.y
local map_size_scaled = map_info.size

local map_scale_factor = nil

if map_horizontal then
    map_scale_factor = 512 / map_info.size.x
else
    map_scale_factor = 512 / map_info.size.y
end

map_size_scaled = map_size_scaled * map_scale_factor
ac.debug("map_size_scaled", map_size_scaled)
ac.log(map_info)

local MapDisplayRenderer = {}

local function mapCoordinateToCanvas(coord)
    return (coord + map_info.offset) * map_scale_factor / map_info.scale
end

function MapDisplayRenderer.drawMapLayout(start_pos, max_size)
    ui.drawImage(map_image_path, start_pos, start_pos + map_size_scaled)
end

function MapDisplayRenderer.drawCar(idx, canvas_size)
    local car = ac.getCar(idx)
    local car_pos = car.position
    local car_map_pos = mapCoordinateToCanvas(Point(car_pos):flat())

    ui.drawCircle(car_map_pos, 5, rgb(0, 1, 0))
end

---@param zone Zone
function MapDisplayRenderer.drawZone(zone)
    for _, seg in zone:getOutsideLine():segment(false):iter() do
        local head_mapped = mapCoordinateToCanvas(seg.head:flat())
        local tail_mapped = mapCoordinateToCanvas(seg.tail:flat())
        ui.drawLine(head_mapped, tail_mapped, rgbm(1, 0, 0, 1), 3)
    end

    for _, seg in zone:getInsideLine():segment(false):iter() do
        local head_mapped = mapCoordinateToCanvas(seg.head:flat())
        local tail_mapped = mapCoordinateToCanvas(seg.tail:flat())
        ui.drawLine(head_mapped, tail_mapped, rgbm(1, 0, 0, 1), 1)
    end
end

---@param clip Clip
function MapDisplayRenderer.drawClip(clip)
    local origin_mapped = mapCoordinateToCanvas(clip.origin:flat())
    local end_mapped = mapCoordinateToCanvas(clip:getEnd():flat())
    ui.drawLine(origin_mapped, end_mapped, rgbm(0, 0, 1, 1), 2)
end

return MapDisplayRenderer
