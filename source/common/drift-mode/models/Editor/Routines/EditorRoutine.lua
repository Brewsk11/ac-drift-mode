local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.Assert')

---@class EditorRoutine : ClassBase
---@field callback fun(payload: any)?
local EditorRoutine = class("EditorRoutine", ModelBase)
EditorRoutine.__model_path = "Editor.Routines.EditorRoutine"
function EditorRoutine:initialize(callback)
    self.callback = callback
end

---@alias EditorRoutine.LightWeightPoiInfo { point: Point, type: ObjectEditorPoi.Type }

---@alias EditorRoutine.Context { course: TrackConfig?, cursor: Cursor?, pois: EditorRoutine.LightWeightPoiInfo[] }

---@param context EditorRoutine.Context
---@return boolean changed
function EditorRoutine:run(context)
    Assert.Error("Abstract method called")
end

---@enum EditorRoutine.AttachResult
EditorRoutine.AttachResult = {
    NoAction = 0,
    RoutineAttached = 1,
    CourseChanged = 2
}

---@param context EditorRoutine.Context
---@return EditorRoutine.AttachResult, EditorRoutine?
function EditorRoutine.attachCondition(context)
    Assert.Error("Abstract method called")
end

---@param context EditorRoutine.Context
---@return boolean
function EditorRoutine:detachCondition(context)
    Assert.Error("Abstract method called")
end

return EditorRoutine
