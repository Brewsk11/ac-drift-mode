local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerRunState : Drawer
---@field drawerCourse DrawerCourse
-- ---@field drawerDriftState DrawerDriftState
---@field drawerZoneState DrawerZoneState
---@field drawerClipState DrawerClipState
local DrawerRunState = class("DrawerRunState", Drawer)

function DrawerRunState:initialize()
end

---@param run_state RunState
function DrawerRunState:draw(run_state)
    if self.drawerCourse and run_state.trackConfig then self.drawerCourse:draw(run_state.trackConfig) end
    -- if self.drawerDriftState and run_state.drift_state then self.drawerDriftState:draw(run_State.drift_state) end
    for _, scoring_object_state in ipairs(run_state.scoringObjectStates) do
        if scoring_object_state.isInstanceOf(ZoneState) then
            self.drawerZoneState:draw(scoring_object_state)
        elseif scoring_object_state.isInstanceOf(ClipState) then
            self.drawerClipState:draw(scoring_object_state)
        else
            Assert.Error("")
        end
    end
end

return DrawerRunState
