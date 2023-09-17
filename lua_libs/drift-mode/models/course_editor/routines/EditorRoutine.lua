local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

---@class EditorRoutine : ClassBase
---@field callback fun(payload: any)?
---@field cursor_ref Cursor?
local EditorRoutine = class("EditorRoutine")
function EditorRoutine:initialize(callback)
    self.callback = callback
end

---@alias EditorRoutine.Context { course: TrackConfig?, cursor: Cursor?, pois: ObjectEditorPoi[] }

---@param context EditorRoutine.Context
function EditorRoutine:run(context)
    Assert.Error("Abstract method called")
end

---@param context EditorRoutine.Context
function EditorRoutine:attachCondition(context)
    Assert.Error("Abstract method called")
end

---@param context EditorRoutine.Context
function EditorRoutine:detachCondition(context)
    Assert.Error("Abstract method called")
end

return EditorRoutine
