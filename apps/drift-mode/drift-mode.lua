local ControlApp = require('drift-mode/apps/ControlApp')
local ScoresApp = require('drift-mode/apps/ScoresApp')
local DriftStatusApp = require('drift-mode/apps/DriftStatusApp')
local CourseView = require('drift-mode/apps/CourseView')

local dt = 0

---@diagnostic disable-next-line: duplicate-set-field
function script.update(_dt)
  dt = _dt
end

function Window_Controls()
  ControlApp.Main(dt)
end

function Window_Scores()
  ScoresApp.Main(dt)
end

function Window_DriftStatus()
  DriftStatusApp.Main(dt)
end

function Window_CourseView()
  CourseView.Main(dt)
end
