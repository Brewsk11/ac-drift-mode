local EditorRoutine = require("drift-mode.models.Editor.Routines.EditorRoutine")
local RaycastUtils = require('drift-mode.RaycastUtils')
local Scorables = require("drift-mode.models.Elements.Scorables.init")
local PointDir = require("drift-mode.models.Common.Point.init")



---@class CheckInZoneArc : EditorRoutine
local CheckInZoneArc = class("CheckInZoneArc", EditorRoutine)
CheckInZoneArc.__model_path = "Editor.Routines.CheckInZoneArc"
function CheckInZoneArc:initialize()
end

---@param context EditorRoutine.Context
function CheckInZoneArc:run(context)
    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("routine_checkinzonearc")
        return
    end

    local point_hit = PointDir.Point(hit)
    local found = false

    for _, obj in ipairs(context.course:getScorables()) do
        if Scorables.ZoneArc.ZoneArc.isInstanceOf(obj) then
            ---@cast obj ZoneArc
            if obj:isInZoneArc(point_hit) then
                context.cursor:registerObject(
                    "routine_checkinzonearc",
                    point_hit,
                    PointDir.Drawers.Precise(rgbm(0, 1, 0, 1)))
                found = true
                break
            end
        end
    end

    if not found then
        context.cursor:registerObject(
            "routine_checkinzonearc",
            point_hit,
            PointDir.Drawers.Precise(rgbm(1, 0, 0, 1)))
    end
end

---@param context EditorRoutine.Context
---@return EditorRoutine.AttachResult, CheckInZoneArc?
function CheckInZoneArc.attachCondition(context)
    if ui.keyboardButtonDown(ui.KeyIndex.LeftControl) then
        return EditorRoutine.AttachResult.RoutineAttached, CheckInZoneArc()
    else
        return EditorRoutine.AttachResult.NoAction
    end
end

---@param context EditorRoutine.Context
function CheckInZoneArc:detachCondition(context)
    if ui.keyboardButtonReleased(ui.KeyIndex.LeftControl) then
        context.cursor:unregisterObject("routine_checkinzonearc")
        return true
    end
    return false
end

return CheckInZoneArc
