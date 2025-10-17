local Handle = require('drift-mode.models.Elements.Handle')
local Point = require("drift-mode.models.Common.Point.Point")

---@class ClipHandle : Handle
---@field point_type ClipHandle.Type
local ClipHandle = class("ClipHandle", Handle)
ClipHandle.__model_path = "Elements.Scorables.Clip.Handle"

---@enum ClipHandle.Type
ClipHandle.Type = {
    Origin = "Origin",
    Ending = "Ending"
}

function ClipHandle:initialize(point, clip, clip_obj_type, drawer)
    Handle.initialize(self, point, clip, drawer)
    self.point_type = clip_obj_type
end

function ClipHandle:set(new_pos)
    local clip = self.element
    ---@cast clip Clip
    if self.point_type == ClipHandle.Type.Origin then
        clip.origin:set(new_pos)
    elseif self.point_type == ClipHandle.Type.Ending then
        clip:setEnd(Point(new_pos))
    end
end

---@param context EditorRoutine.Context
function ClipHandle:onDelete(context)
    table.removeItem(context.course.scorables, self.element)
end

return ClipHandle
