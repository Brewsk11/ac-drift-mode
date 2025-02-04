local ControlApp = require('drift-mode/apps/ControlApp')
local DriftStatusApp = require('drift-mode/apps/DriftStatusApp')

function Window_Controls()
  ControlApp.Main()
end

function Window_Scores()
  ControlApp.WindowScores()
end

function Window_DriftStatus()
  DriftStatusApp.Main()
end
