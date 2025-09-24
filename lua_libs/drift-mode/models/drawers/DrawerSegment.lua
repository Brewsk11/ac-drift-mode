local Drawer = require('drift-mode/models/Drawers/Drawer')

---@class DrawerSegment : Drawer
local DrawerSegment = class("DrawerSegment", Drawer)
DrawerSegment.__model_path = "Drawers.DrawerSegment"

function DrawerSegment:initialize()
end

---@param segment Segment
function DrawerSegment:draw(segment)
end

return DrawerSegment
