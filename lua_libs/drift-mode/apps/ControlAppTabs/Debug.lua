local EventSystem = require('drift-mode/eventsystem')
local ConfigIO = require('drift-mode/configio')

local Debug = {}


function Debug.drawUIDebug(scoring_objects)
    if ui.button("Save scoring objects") then
        ConfigIO.saveConfig(ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/scoring.json", scoring_objects)
    end

    if ui.button("Load scoring objects") then
        local scoring_objects = ConfigIO.loadConfig(ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/scoring.json")

        EventSystem.queue(EventSystem.Signal.ScoringObjectStatesReset, {})

        for _, object in ipairs(scoring_objects) do
            EventSystem.queue(EventSystem.Signal.ScoringObjectState(object))
        end
    end
end

return Debug
