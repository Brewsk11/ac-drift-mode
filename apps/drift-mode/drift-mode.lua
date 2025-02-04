local ControlApp = require('drift-mode/apps/ControlApp')
local ScoresApp = require('drift-mode/apps/ScoresApp')
local DriftStatusApp = require('drift-mode/apps/DriftStatusApp')

function Window_Controls()
  ControlApp.Main()
end

function Window_Scores()
  ScoresApp.Main()
end

function Window_DriftStatus()
  DriftStatusApp.Main()
end
