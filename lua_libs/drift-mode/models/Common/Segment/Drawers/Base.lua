local Drawer = require('drift-mode/models/Drawer')

---@class DrawerSegment : Drawer
local DrawerSegment = class("DrawerSegment", Drawer)
DrawerSegment.__model_path = "Common.Segment.Drawers.Base"

function DrawerSegment:initialize()
end

---@param segment Segment
function DrawerSegment:draw(segment)
end

return DrawerSegment
