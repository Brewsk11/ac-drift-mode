local DrawerRunState = require('drift-mode.models.Drawers.DrawerRunState')
local DrawerCoursePlay = require("drift-mode.models.Elements.Course.Drawers.DrawerCoursePlay")
local DrawerZoneStatePlay = require('drift-mode.models.Drawers.DrawerZoneStatePlay')
local DrawerClipStatePlay = require('drift-mode.models.Drawers.DrawerClipStatePlay')

---@class DrawerRunStatePlay : DrawerRunState
local DrawerRunStatePlay = class("DrawerRunStatePlay", DrawerRunState)
DrawerRunStatePlay.__model_path = "Elements.Course.Drawers.DrawerRunStatePlay"

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
