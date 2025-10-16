local RaycastUtils = require('drift-mode.RaycastUtils')
local Resources = require('drift-mode.Resources')

local PointDir = require("drift-mode.models.Common.Point.init")
local Point = PointDir.Point
local POIs = require("drift-mode.models.Editor.POIs.init")
local EditorRoutine = require("drift-mode.models.Editor.Routines.EditorRoutine")


---@class RoutineMovePoi : EditorRoutine
---@field poi ObjectEditorPoi?
---@field offset vec3?
---@field drawerPoint DrawerObjectEditorPoi --- To highlight possible pois to interact with
local RoutineMovePoi = class("RoutineMovePoi", EditorRoutine)
RoutineMovePoi.__model_path = "Editor.Routines.RoutineMovePoi"
function RoutineMovePoi:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self.poi = nil
    self.offset = nil
    self.drawerPoint = POIs.Drawers.Simple(PointDir.Drawers.Simple(Resources.Colors.EditorInactivePoi, 0.5))
    self.last_pos = nil
    self.min_change = 0.01
end

---@param pois ObjectEditorPoi[]
---@param origin vec3
---@param radius number
---@return ObjectEditorPoi?
---@private
function RoutineMovePoi:findClosestPoi(pois, origin, radius)
    local closest_dist = radius
    closest_poi = nil ---@type ObjectEditorPoi?
    if origin then
        for _, poi in ipairs(pois) do
            local distance = origin:distance(poi.point:value())
            if distance < closest_dist then
                closest_poi = poi
                closest_dist = distance
            end
        end
    end
    return closest_poi
end

---@param context EditorRoutine.Context
function RoutineMovePoi:run(context)
    context.cursor:unregisterObject("pois")

    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("move_poi_selector")
        return false
    end

    local new_pos = hit + self.offset
    if self.last_pos ~= nil then
        local dist_between = self.last_pos:distance(new_pos)
        if dist_between < self.min_change then
            return false
        end
    end

    self.last_pos = new_pos
    self.poi:set(new_pos)

    context.cursor:registerObject(
        "move_poi_selector",
        Point(hit + self.offset),
        PointDir.Drawers.Sphere(rgbm(1.5, 3, 0, 3)))

    if self.poi.isInstanceOf(POIs.Zone) then
        local poi_zone = self.poi ---@type ZoneHandle # TODO: clean up class names
        poi_zone.zone:setDirty()
    end

    return true
end

---@param context EditorRoutine.Context
---@param poi ObjectEditorPoi|Handle
function RoutineMovePoi:deletePoi(context, poi)
    if poi.poi_type == POIs.Base.Type.StartingPoint then
        context.course.startingPoint = nil
    elseif poi.poi_type == POIs.Base.Type.Segment then
        local poi_segment = poi ---@type PoiSegment
        if poi_segment.segment_type == POIs.Segment.Type.StartLine then
            context.course.startLine = nil
        elseif poi_segment.segment_type == POIs.Segment.Type.FinishLine then
            context.course.finishLine = nil
        end
    else
        ---@cast poi Handle
        poi:onDelete(context)
    end
    self.callback()
end

---@param context EditorRoutine.Context
function RoutineMovePoi:attachCondition(context)
    ---TODO: Massive performance cow

    context.cursor:unregisterObject("move_poi_attach")

    local light_pois = {}
    for _, poi in ipairs(context.pois) do light_pois[#light_pois + 1] = { point = poi.point, poi_type = poi.poi_type } end

    context.cursor:registerObject("pois", light_pois, self.drawerPoint)

    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        context.cursor:unregisterObject("pois")
        return false
    end

    ---@type ObjectEditorPoi?
    local poi = self:findClosestPoi(context.pois, hit, 1)
    if not poi then return false end

    local color = rgbm(0, 3, 1.5, 3)
    if ui.keyboardButtonDown(ui.KeyIndex.Control) then
        color = rgbm(3, 0, 1.5, 3)
    end

    context.cursor:registerObject("move_poi_attach", poi.point, PointDir.Drawers.Simple(color))

    self.poi = poi
    self.offset = poi.point:value() - hit

    -- Handle removing POIs
    if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.mouseClicked() then
        self:deletePoi(context, self.poi)
        return false
    end

    return ui.mouseClicked()
end

---@param context EditorRoutine.Context
function RoutineMovePoi.detachCondition(context)
    return ui.mouseReleased()
end

return RoutineMovePoi
