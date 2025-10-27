local Assert = require('drift-mode.Assert')

local Drawer = require("drift-mode.models.Drawer")
local ZoneState = require("drift-mode.models.Elements.Scorables.Zone.ZoneState")
local ClipState = require("drift-mode.models.Elements.Scorables.Clip.ClipState")
local ZoneArcState = require("drift-mode.models.Elements.Scorables.ZoneArc.ZoneArcState")

---@class DrawerRunState : Drawer
---@field drawerCourse DrawerCourse
-- ---@field drawerDriftState DrawerDriftState
---@field drawerZoneState DrawerZoneState
---@field drawerClipState DrawerClipState
---@field drawerZoneArcState DrawerZoneArcState
local DrawerRunState = class("DrawerRunState", Drawer)
DrawerRunState.__model_path = "Elements.Course.Drawers.DrawerRunState"

function DrawerRunState:initialize()
end

---@param run_state RunState
function DrawerRunState:draw(run_state)
    if self.drawerCourse and run_state.trackConfig then self.drawerCourse:draw(run_state.trackConfig) end
    -- if self.drawerDriftState and run_state.drift_state then self.drawerDriftState:draw(run_State.drift_state) end
    for _, scoring_object_state in ipairs(run_state.scoringObjectStates) do
        if scoring_object_state.isInstanceOf(ZoneState) then
            ---@cast scoring_object_state ZoneState
            self.drawerZoneState:draw(scoring_object_state)
        elseif scoring_object_state.isInstanceOf(ClipState) then
            ---@cast scoring_object_state ClipState
            self.drawerClipState:draw(scoring_object_state)
        elseif scoring_object_state.isInstanceOf(ZoneArcState) then
            ---@cast scoring_object_state ZoneArcState
            self.drawerZoneArcState:draw(scoring_object_state)
        else
            Assert.Error("")
        end
    end
end

return DrawerRunState
