local Poi = require('drift-mode.models.Elements.Poi')
local Point = require("drift-mode.models.Common.Point.Point")

---@class PoiClip : Poi
---@field clip Clip
---@field point_type PoiClip.Type
local PoiClip = class("PoiClip", Poi)
PoiClip.__model_path = "Elements.Scorables.Clip.Poi"

---@enum PoiClip.Type
PoiClip.Type = {
    Origin = "Origin",
    Ending = "Ending"
}

function PoiClip:initialize(point, clip, clip_obj_type)
    Poi.initialize(self, point)
    self.clip = clip
    self.point_type = clip_obj_type
end

function PoiClip:set(new_pos)
    if self.point_type == PoiClip.Type.Origin then
        self.clip.origin:set(new_pos)
    elseif self.point_type == PoiClip.Type.Ending then
        self.clip:setEnd(Point(new_pos))
    end
end

---@param clip Clip
---@return PoiClip[]
function PoiClip.gatherPois(clip)
    local pois = {}
    pois[#pois + 1] = PoiClip(
        clip.origin,
        clip,
        PoiClip.Type.Origin
    )
    pois[#pois + 1] = PoiClip(
        clip:getEnd(),
        clip,
        PoiClip.Type.Ending
    )
    return pois
end

---@param context EditorRoutine.Context
function PoiClip:onDelete(context)
    table.removeItem(context.course.scorables, self.clip)
end

return PoiClip
