local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerRunStatePlay : DrawerRunState
local DrawerRunStatePlay = class("DrawerRunStatePlay", DrawerRunState)

function DrawerRunStatePlay:initialize()
    self.drawerCourse = DrawerCoursePlay()
    self.drawerZoneState = DrawerZoneStatePlay()
    self.drawerClipState = DrawerClipStatePlay()

    self.courseDone = false
end

---@param run_state RunState
function DrawerRunStatePlay:draw(run_state)
    render.setDepthMode(render.DepthMode.ReadOnly)

    if run_state:getFinished() then
        self.drawerZoneState:setShowZoneScorePoints(true)
    else
        self.drawerZoneState:setShowZoneScorePoints(false)
    end

    DrawerRunState.draw(self, run_state)
end

return DrawerRunStatePlay
