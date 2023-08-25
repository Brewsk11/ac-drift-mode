local CourseEditor = require('drift-mode/courseeditor')

local editor = CourseEditor()

function WindowMain(dt)
  editor:drawUI(dt)
end