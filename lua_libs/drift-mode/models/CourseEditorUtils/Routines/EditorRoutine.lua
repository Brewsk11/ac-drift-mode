local Assert = require('drift-mode/assert')

---@class EditorRoutine : ClassBase
---@field callback fun(payload: any)?
local EditorRoutine = class("EditorRoutine")
EditorRoutine.__model_path = "CourseEditorUtils.Routines.EditorRoutine"
function EditorRoutine:initialize(callback)
    self.callback = callback
end

---@alias EditorRoutine.LightWeightPoiInfo { point: Point, type: ObjectEditorPoi.Type }

---@alias EditorRoutine.Context { course: TrackConfig?, cursor: Cursor?, pois: EditorRoutine.LightWeightPoiInfo[] }

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
