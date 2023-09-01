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
    if self.drawerZoneState then
        for _, zone_state in ipairs(run_state.zoneStates) do
            self.drawerZoneState:draw(zone_state)
        end
    end

    if self.drawerClipState then
        for _, clip_state in ipairs(run_state.clipStates) do
            self.drawerClipState:draw(clip_state)
        end
    end
end

return DrawerRunState
