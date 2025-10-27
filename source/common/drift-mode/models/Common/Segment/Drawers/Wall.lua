local DrawerSegment = require("drift-mode.models.Common.Segment.Drawers.Base")
local RaycastUtils = require("drift-mode.RaycastUtils")


---@class DrawerSegmentWall : DrawerSegment
---@field color rgbm
---@field height number
local DrawerSegmentWall = class("DrawerSegmentWall", DrawerSegment)
DrawerSegmentWall.__model_path = "Common.Segment.Drawers.Wall"

function DrawerSegmentWall:initialize(color, height)
    self.color = color or rgbm(1, 1, 1, 1)
    self.height = height or 1
    self.aligned = true

    self:cacheMethod("getQuadCoords")
end

function DrawerSegmentWall:getQuadCoords(segment, aligned)
    if aligned then
        return {
            RaycastUtils.getAlignedToTrack(segment:getHead():value()),
            RaycastUtils.getAlignedToTrack(segment:getTail():value()),
            RaycastUtils.getAlignedToTrack(segment:getTail():value()) + vec3(0, self.height, 0),
            RaycastUtils.getAlignedToTrack(segment:getHead():value()) + vec3(0, self.height, 0)
        }
    else
        return {
            segment:getHead():value(),
            segment:getTail():value(),
            segment:getTail():value() + vec3(0, self.height, 0),
            segment:getHead():value() + vec3(0, self.height, 0)
        }
    end
end

---@param segment Segment
function DrawerSegmentWall.draw(self, segment)
    render.quad(
        self:getQuadCoords(segment, self.aligned)[1],
        self:getQuadCoords(segment, self.aligned)[2],
        self:getQuadCoords(segment, self.aligned)[3],
        self:getQuadCoords(segment, self.aligned)[4],
        self.color
    )
end

return DrawerSegmentWall
