local SettingsApp = require('Settings.Main')
local ScoreTableApp = require('ScoreTable.Main')
local DriftStatusApp = require('DriftStatus.Main')
local CourseViewApp = require('CourseView.Main')

local dt = 0

---@diagnostic disable-next-line: duplicate-set-field
function script.update(_dt)
  dt = _dt
end

function Window_Controls()
  SettingsApp.Main(dt)
end

function Window_Scores()
  ScoreTableApp.Main(dt)
end

function Window_DriftStatus()
  DriftStatusApp.Main(dt)
end

function Window_CourseView()
  CourseViewApp.Main(dt)
end
