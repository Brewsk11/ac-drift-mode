local Handle = require('drift-mode.models.Elements.Handle')
local Point = require("drift-mode.models.Common.Point.Point")

---@class ClipHandle : Handle
---@field clip Clip
---@field point_type ClipHandle.Type
local ClipHandle = class("ClipHandle", Handle)
ClipHandle.__model_path = "Elements.Scorables.Clip.Handle"

---@enum ClipHandle.Type
ClipHandle.Type = {
    Origin = "Origin",
    Ending = "Ending"
}

function ClipHandle:initialize(point, clip, clip_obj_type)
    Handle.initialize(self, point)
    self.clip = clip
    self.point_type = clip_obj_type
end

function ClipHandle:set(new_pos)
    if self.point_type == ClipHandle.Type.Origin then
        self.clip.origin:set(new_pos)
    elseif self.point_type == ClipHandle.Type.Ending then
        self.clip:setEnd(Point(new_pos))
    end
end

---@param context EditorRoutine.Context
function ClipHandle:onDelete(context)
    table.removeItem(context.course.scorables, self.clip)
end

return ClipHandle
