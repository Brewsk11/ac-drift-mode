local EventSystem = require('drift-mode.eventsystem')
local listener_id = EventSystem:registerListener("apptab-editor")

local CourseEditor = require('Settings.tabs.Editor.courseeditor')


---@type EditorsState
local editors_state = nil


local Editor = {}


local course_editor = CourseEditor()
local course_editor_enabled = false

function Editor.drawUIEditor()
    EventSystem:listen(listener_id, EventSystem.Signal.EditorsStateChanged, function(payload)
        editors_state = payload
    end)

    if editors_state == nil then return end

    if ui.checkbox("Enable course editor", course_editor_enabled) then
        course_editor_enabled = not course_editor_enabled
        editors_state.isTrackSetup = course_editor_enabled
        EventSystem:emit(EventSystem.Signal.EditorsStateChanged, editors_state)
    end

    if course_editor_enabled then
        course_editor:drawUI()
        course_editor:runEditor()
    end
end

return Editor
