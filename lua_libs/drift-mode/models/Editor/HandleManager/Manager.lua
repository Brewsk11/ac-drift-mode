---@class HandleManager
---@field private id string
---@field protected shared_data { sets_counter: integer, handle_id: HandleId, vector: vec3 }
local HandleManager = class("HandleManager")
HandleManager.__model_path = "Editor.HandleManager.Manager"

function HandleManager:initialize(id)
    self.id = id
    self.shared_data = ac.connect(self:getStructDef())
end

function HandleManager:getStructDef()
    local struct_id = 'drift-mode.HandleManagers.' .. self.id
    local struct = {
        ac.StructItem.key(struct_id),
        sets_counter = ac.StructItem.int64(),
        handle_id = ac.StructItem.string(),
        vector = ac.StructItem.vec3()
    }
    return struct
end

return class.emmy(HandleManager, HandleManager.initialize)
