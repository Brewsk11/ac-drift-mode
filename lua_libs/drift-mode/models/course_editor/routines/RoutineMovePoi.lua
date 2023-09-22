local Assert = require('drift-mode/assert')
local RaycastUtils = require('drift-mode/RaycastUtils')
local S = require('drift-mode/serializer')
local Resources = require('drift-mode/Resources')

---@class RoutineMovePoi : EditorRoutine
---@field poi ObjectEditorPoi?
---@field offset vec3?
---@field drawerPoint DrawerObjectEditorPoi --- To highlight possible pois to interact with
local RoutineMovePoi = class("RoutineMovePoi", EditorRoutine)
function RoutineMovePoi:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self.poi = nil
    self.offset = nil
    self.drawerPoint = DrawerObjectEditorPoi(DrawerPointSimple(Resources.ColorEditorInactivePoi, 0.5))
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
        return
    end

    self.poi:set(hit + self.offset)

    context.cursor:registerObject(
        "move_poi_selector",
        Point(hit + self.offset),
        DrawerPointSphere(rgbm(1.5, 3, 0, 3)))

    if self.poi.isInstanceOf(PoiZone) then
        local poi_zone = self.poi ---@type PoiZone
        poi_zone.zone:setDirty()
    end
end

---@param context EditorRoutine.Context
---@param poi ObjectEditorPoi
function RoutineMovePoi:deletePoi(context, poi)
    if poi.poi_type == ObjectEditorPoi.Type.Zone then
        local poi_zone = poi ---@type PoiZone
        if poi_zone.point_type == PoiZone.Type.FromInsideLine then
            poi_zone.zone:getInsideLine():remove(poi_zone.point_index)
        elseif poi_zone.point_type == PoiZone.Type.FromOutsideLine then
            poi_zone.zone:getOutsideLine():remove(poi_zone.point_index)
        elseif poi_zone.point_type == PoiZone.Type.Center then
            ui.modalPopup(
                "Deleting zone",
                "Are you sure you want to delete the zone?",
                function()
                    table.removeItem(context.course.scoringObjects, poi_zone.zone)
                end
            )
        end
    elseif poi.poi_type == ObjectEditorPoi.Type.Clip then
        local poi_clip = poi ---@type PoiClip
        table.removeItem(context.course.scoringObjects, poi_clip.clip)
    elseif poi.poi_type == ObjectEditorPoi.Type.StartingPoint then
        context.course.startingPoint = nil
    elseif poi.poi_type == ObjectEditorPoi.Type.Segment then
        local poi_segment = poi ---@type PoiSegment
        if poi_segment.segment_type == PoiSegment.Type.StartLine then
            context.course.startLine = nil
        elseif poi_segment.segment_type == PoiSegment.Type.FinishLine then
            context.course.finishLine = nil
        end
    end
    self.callback()
end

---@param context EditorRoutine.Context
function RoutineMovePoi:attachCondition(context)
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

    context.cursor:registerObject("move_poi_attach", poi.point, DrawerPointSphere(color))

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
