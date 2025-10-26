local RaycastUtils = require('drift-mode.RaycastUtils')
local Resources = require('drift-mode.Resources')

local PointDir = require("drift-mode.models.Common.Point.init")
local Point = PointDir.Point
local POIs = require("drift-mode.models.Editor.POIs.init")
local EditorRoutine = require("drift-mode.models.Editor.Routines.EditorRoutine")
local HandleSetter = require("drift-mode.models.Editor.HandleManager.Setter")


---@class RoutineMovePoi : EditorRoutine
---@field poi Handle?
---@field offset vec3?
---@field drawerPoint DrawerPoint --- To highlight possible pois to interact with
local RoutineMovePoi = class("RoutineMovePoi", EditorRoutine)
RoutineMovePoi.__model_path = "Editor.Routines.RoutineMovePoi"
function RoutineMovePoi:initialize(callback)
    EditorRoutine.initialize(self, callback)
    self.poi = nil
    self.offset = nil
    self.drawerPoint = POIs.Drawers.Simple(PointDir.Drawers.Simple(Resources.Colors.EditorInactivePoi, 0.5))
    self.last_pos = nil
    self.min_change = 0.01
    self.handle_setter = HandleSetter("editor")
end

---@param pois Handle[]
---@param origin vec3
---@param radius number
---@return Handle?
---@private
function RoutineMovePoi.findClosestPoi(pois, origin, radius)
    local closest_dist = radius
    local closest_poi = nil ---@type Handle?
    if origin then
        for _, poi in pairs(pois) do
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
    self.handle_setter:set(self.poi:getId(), new_pos)

    self.poi:set(new_pos)

    context.cursor:registerObject(
        "move_poi_selector",
        Point(hit + self.offset),
        PointDir.Drawers.Sphere(rgbm(1.5, 3, 0, 3)))

    self.poi:onChanged()
    return true
end

---@param context EditorRoutine.Context
---@return RoutineMovePoi?
function RoutineMovePoi.attachCondition(context)
    ---TODO: Massive performance cow

    context.cursor:unregisterObject("move_poi_attach")

    ---@type vec3?
    local hit = RaycastUtils.getTrackRayMouseHit()
    if not hit then
        return nil
    end

    ---@type Handle?
    local poi = RoutineMovePoi.findClosestPoi(context.pois, hit, 1)
    if not poi then return nil end

    local color = rgbm(0, 3, 1.5, 3)
    if ui.keyboardButtonDown(ui.KeyIndex.Control) then
        color = rgbm(3, 0, 1.5, 3)
    end

    context.cursor:registerObject("move_poi_attach", poi.point, PointDir.Drawers.Simple(color))

    -- Handle removing POIs
    if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.mouseClicked() then
        poi:onDelete(context)
        return nil
    end

    if ui.mouseClicked() then
        local routine = RoutineMovePoi(context)
        routine.poi = poi
        routine.offset = poi.point:value() - hit
        return routine
    end

    return nil
end

---@param context EditorRoutine.Context
function RoutineMovePoi:detachCondition(context)
    if ui.mouseReleased() then
        self.handle_setter:reset()
        self.handle_setter = nil
        return true
    end
    return false
end

return RoutineMovePoi
