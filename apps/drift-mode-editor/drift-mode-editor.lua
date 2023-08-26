local EventSystem  = require('drift-mode/eventsystem')
local CourseEditor = require('drift-mode/courseeditor')
require('drift-mode/models')

local listener_id = EventSystem.registerListener('editor-app')

---@type GameState
local game_state = GameState.new()

local course_editor = CourseEditor()
local course_editor_enabled = false

function WindowMain(dt)

  if ui.checkbox("Enable course editor", course_editor_enabled) then
    course_editor_enabled = not course_editor_enabled
    game_state.isTrackSetup = course_editor_enabled
    EventSystem.emit("GameStateChanged", game_state)
  end

  if course_editor_enabled then
    course_editor:drawUI(dt)
  end
end
