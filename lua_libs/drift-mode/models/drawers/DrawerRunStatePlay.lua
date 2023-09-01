local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerRunStatePlay : DrawerRunState
---@field drawerCourse DrawerCourse
-- ---@field drawerDriftState DrawerDriftState
---@field drawerZoneState DrawerZoneState
-- ---@field drawerClipState DrawerClipState
local DrawerRunStatePlay = class("DrawerRunStatePlay", DrawerRunState)

function DrawerRunStatePlay:initialize()
    self.drawerCourse = nil
    self.drawerZoneState = DrawerZoneStatePlay()
    self.drawerClipState = DrawerClipStatePlay()
end

---@param run_state RunState
function DrawerRunStatePlay:draw(run_state)
    render.setDepthMode(render.DepthMode.Normal)
    DrawerRunState.draw(self, run_state)
end

return DrawerRunStatePlay
