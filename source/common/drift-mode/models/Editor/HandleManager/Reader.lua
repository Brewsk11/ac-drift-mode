local HandleManager = require("drift-mode.models.Editor.HandleManager.Manager")

---@class HandleReader : HandleManager
---@field private reads_counter integer
local HandleReader = class("HandleReader", HandleManager)
HandleReader.__model_path = "Editor.HandleManager.Reader"

---@overload fun(id: string) : HandleReader
function HandleReader:initialize(id)
    HandleManager.initialize(self, id)
    self.reads_counter = 0
end

---@param callback fun(handle_id: HandleId, vector: vec3)
function HandleReader:listen(callback)
    if self.shared_data.sets_counter == 0 then
        self.reads_counter = 0
    end

    if self.shared_data.vector == nil or self.shared_data.handle_id == nil then
        return
    end

    if self.reads_counter < self.shared_data.sets_counter and self.shared_data.vector ~= nil then
        callback(self.shared_data.handle_id, self.shared_data.vector)
        self.reads_counter = self.shared_data.sets_counter
    end
end

return class.emmy(HandleReader, HandleReader.initialize)
