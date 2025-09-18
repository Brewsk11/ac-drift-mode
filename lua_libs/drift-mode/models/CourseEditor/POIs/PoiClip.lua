local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class PoiClip : ObjectEditorPoi
---@field clip Clip
---@field point_type PoiClip.Type
local PoiClip = class("PoiClip", ObjectEditorPoi)

---@enum PoiClip.Type
PoiClip.Type = {
    Origin = "Origin",
    Ending = "Ending"
}

function PoiClip:initialize(point, clip, clip_obj_type)
    ObjectEditorPoi.initialize(self, point, ObjectEditorPoi.Type.Clip)
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

return PoiClip
