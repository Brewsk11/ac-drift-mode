local ModelBase = require("drift-mode.models.ModelBase")
---Base class for object that can be drawn in the world space
---@class WorldObject : ClassBase
---@field protected drawer Drawer?
local WorldObject = class("WorldObject", ModelBase)
WorldObject.__model_path = "WorldObject"

function WorldObject:initialize()
end

function WorldObject:draw()
    if self.drawer then
        self.drawer:draw(self)
    end
end

function WorldObject:getDrawer()
    return self.drawer()
end

---@param drawer Drawer?
function WorldObject:setDrawer(drawer)
    self.drawer = drawer
end

return WorldObject
