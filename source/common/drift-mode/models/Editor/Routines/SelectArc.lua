local Assert = require('drift-mode.Assert')
local RaycastUtils = require('drift-mode.RaycastUtils')

local EditorRoutine = require('drift-mode.models.Editor.Routines.EditorRoutine')
local SegmentDir = require("drift-mode.models.Common.Segment.init")
local Segment = SegmentDir.Segment
local PointDir = require("drift-mode.models.Common.Point.init")
local Point = PointDir.Point
local ArcDir = require("drift-mode.models.Common.Arc.init")
local Arc = ArcDir.Arc

---@class RoutineSelectArc : EditorRoutine
---@field private _start Point
---@field private _end Point
---@field private _midpoint Point
local RoutineSelectArc = class("RoutineSelectArc", EditorRoutine)
RoutineSelectArc.__model_path = "Editor.Routines.SelectArc"

function RoutineSelectArc:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self._start = nil
    self._end = nil
    self._midpoint = nil
    self._arc = nil
end

---@param context EditorRoutine.Context
function RoutineSelectArc:run(context)
    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("routine_select_selector")
        context.cursor:unregisterObject("routine_select_arc")
        context.cursor:unregisterObject("routine_select_arc_points")
        return false
    end

    context.cursor:registerObject(
        "routine_select_selector",
        Point(hit),
        PointDir.Drawers.Sphere(rgbm(1.5, 3, 0, 3))
    )

    if self._start == nil then
        if ui.mouseClicked() then
            self._start = Point(hit)
            return false
        end
    elseif self._end == nil then
        if ui.mouseClicked() then
            self._end = Point(hit)
            return false
        end
        context.cursor:registerObject(
            "routine_select_arc",
            Segment(self._start, Point(hit)),
            SegmentDir.Drawers.Line(rgbm(0, 0, 3, 1))
        )
    else -- self._midpoint == nil
        local arc = Arc.fromTriplet(self._start, self._end, Point(hit))
        if arc == nil then return end
        if ui.mouseClicked() then
            self._midpoint = Point(hit)
            self._arc = arc
            return true
        end
        local arr = PointDir.Array()
        arr:append(self._start)
        arr:append(self._end)
        context.cursor:registerObject(
            "routine_select_arc_points",
            arr,
            PointDir.Drawers.ArraySimple()
        )
        context.cursor:registerObject(
            "routine_select_arc",
            arc,
            ArcDir.Drawers.Debug(rgbm(0, 0, 3, 1))
        )
    end
end

---@param context EditorRoutine.Context
function RoutineSelectArc:attachCondition(context)
    Assert.Error("Manually attachable")
end

---@param context EditorRoutine.Context
function RoutineSelectArc:detachCondition(context)
    if self._arc ~= nil then
        if self.callback then self.callback(self._arc) end
        return true
    end
    return false
end

return RoutineSelectArc
