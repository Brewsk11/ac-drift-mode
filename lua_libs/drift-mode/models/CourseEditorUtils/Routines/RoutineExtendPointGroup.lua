local Assert = require('drift-mode/assert')
local RaycastUtils = require('drift-mode/RaycastUtils')

local EditorRoutine = require('drift-mode/models/CourseEditorUtils/Routines/EditorRoutine')
local Point = require("drift-mode.models.Point")
local Drawers = require("drift-mode.models.Drawers")
local Segment = require("drift-mode.models.Segment")

---@class RoutineExtendPointGroup : EditorRoutine
---@field point_group PointGroup
local RoutineExtendPointGroup = class("RoutineExtendPointGroup", EditorRoutine)
RoutineExtendPointGroup.__model_path = "CourseEditorUtils.Routines.RoutineExtendPointGroup"
function RoutineExtendPointGroup:initialize(point_group)
    EditorRoutine.initialize(self, nil)
    self.point_group = point_group
end

---@param context EditorRoutine.Context
function RoutineExtendPointGroup:run(context)
    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("extend_routine_selector")
        context.cursor:unregisterObject("extend_routine_segment_to_last")
        return
    end

    context.cursor:registerObject("extend_routine_selector", Point(hit), Drawers.DrawerPointSphere(rgbm(1.5, 3, 0, 3)))

    if self.point_group:count() > 0 then
        context.cursor:registerObject(
            "extend_routine_segment_to_last",
            Segment(self.point_group:last(), Point(hit)),
            Drawers.DrawerSegmentLine(rgbm(0, 3, 0, 3))
        )
    end

    if ui.mouseClicked() then
        self.point_group:append(Point(hit))
    end
end

---@param context EditorRoutine.Context
function RoutineExtendPointGroup:attachCondition(context)
    Assert.Error("Manually attachable")
end

---@param context EditorRoutine.Context
function RoutineExtendPointGroup:detachCondition(context)
    return ui.mouseClicked(ui.MouseButton.Right)
end

return RoutineExtendPointGroup
