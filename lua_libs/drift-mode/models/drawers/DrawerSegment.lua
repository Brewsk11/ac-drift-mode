local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class DrawerSegment : Drawer
local DrawerSegment = class("DrawerSegment", Drawer)

function DrawerSegment:initialize()
end

---@param segment Segment
function DrawerSegment:draw(segment)
end

return DrawerSegment
