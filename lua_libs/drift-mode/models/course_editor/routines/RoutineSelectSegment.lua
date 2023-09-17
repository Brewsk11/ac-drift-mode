local Assert = require('drift-mode/assert')
local AsyncUtils = require('drift-mode/asynchelper')
local S = require('drift-mode/serializer')

---@class RoutineSelectSegment : EditorRoutine
---@field private segment Segment
local RoutineSelectSegment = class("RoutineSelectSegment", EditorRoutine)

function RoutineSelectSegment:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self.segment = Segment()
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:run(context)
    ---@type vec3?
    local hit = AsyncUtils.taskTrackRayHit()
    if not hit then
        self.cursor_ref:unregisterObject("routine_select_selector")
        self.cursor_ref:unregisterObject("routine_select_segment")
        return
    end

    self.cursor_ref:registerObject(
        "routine_select_selector",
        Point(hit),
        DrawerPointSphere(rgbm(1.5, 3, 0, 3))
    )

    -- When head has already been set
    if self.segment.head then
        if ui.mouseClicked() then
            self.segment.tail = Point(hit)
        end
        self.cursor_ref:registerObject(
            "routine_select_segment",
            Segment(self.segment.head, Point(hit)),
            DrawerSegmentLine(rgbm(0, 0, 3, 1))
        )
    end

    -- To set the head
    if self.segment.head == nil and ui.mouseClicked() then
        self.segment.head = Point(hit)
    end
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:attachCondition(context)
    Assert.Error("Manually attachable")
end

---@param context EditorRoutine.Context
function RoutineSelectSegment:detachCondition(context)
    if self.segment.tail then
        if self.callback then self.callback(self.segment) end
        return true
    end
    return false
end

return RoutineSelectSegment
