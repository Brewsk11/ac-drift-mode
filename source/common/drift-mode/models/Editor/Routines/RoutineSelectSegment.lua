local Assert = require('drift-mode.Assert')
local RaycastUtils = require('drift-mode.RaycastUtils')

local EditorRoutine = require('drift-mode.models.Editor.Routines.EditorRoutine')
local SegmentDir = require("drift-mode.models.Common.Segment.init")
local Segment = SegmentDir.Segment
local PointDir = require("drift-mode.models.Common.Point.init")
local Point = PointDir.Point


---@class RoutineSelectSegment : EditorRoutine
---@field private segment Segment
local RoutineSelectSegment = class("RoutineSelectSegment", EditorRoutine)
RoutineSelectSegment.__model_path = "Editor.Routines.RoutineSelectSegment"

function RoutineSelectSegment:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self.segment = Segment()
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:run(context)
    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("routine_select_selector")
        context.cursor:unregisterObject("routine_select_segment")
        return
    end

    context.cursor:registerObject(
        "routine_select_selector",
        Point(hit),
        PointDir.Drawers.Sphere(rgbm(1.5, 3, 0, 3))
    )

    -- When head has already been set
    if self.segment:getHead() ~= nil then
        if ui.mouseClicked() then
            self.segment:setTail(Point(hit))
            return true
        end
        context.cursor:registerObject(
            "routine_select_segment",
            Segment(self.segment:getHead(), Point(hit)),
            SegmentDir.Drawers.Line(rgbm(0, 0, 3, 1))
        )
    elseif ui.mouseClicked() then
        self.segment:setHead(Point(hit))
        return true
    end

    return false
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:attachCondition(context)
    Assert.Error("Manually attachable")
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:detachCondition(context)
    if self.segment:getTail() then
        if self.callback then self.callback(self.segment) end
        return true
    end
    return false
end

return RoutineSelectSegment
