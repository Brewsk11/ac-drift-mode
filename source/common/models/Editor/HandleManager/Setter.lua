local HandleManager = require("drift-mode.models.Editor.HandleManager.Manager")

---@class HandleSetter : HandleManager
local HandleSetter = class("HandleSetter", HandleManager)
HandleSetter.__model_path = "Editor.HandleManager.Setter"

---@overload fun(id: string) : HandleSetter
function HandleSetter:initialize(id)
    HandleManager.initialize(self, id)
    self:reset()
end

function HandleSetter:reset()
    self.shared_data.sets_counter = 0
end

function HandleSetter:set(handle_id, vector)
    self.shared_data.handle_id = handle_id
    self.shared_data.vector = vector
    self.shared_data.sets_counter = self.shared_data.sets_counter + 1
end

return class.emmy(HandleSetter, HandleSetter.initialize)
