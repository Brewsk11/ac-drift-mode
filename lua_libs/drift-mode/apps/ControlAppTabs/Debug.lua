local EventSystem = require('drift-mode.eventsystem')
local listener_id = EventSystem:registerListener("app-debug-tab")

local ConfigIO = require('drift-mode.configio')

local Debug = {}

---@type ScorableState[]?
local scoring_object_states = nil

function Debug.drawUIDebug()
    EventSystem:listen(listener_id, EventSystem.Signal.ScorableStateChanged, function(payload)
        if scoring_object_states == nil then return end
        for idx, obj in ipairs(scoring_object_states) do
            if obj:getName() == payload.name then
                if obj:updatesFully() then
                    scoring_object_states[idx] = payload.payload
                else
                    obj:consumeUpdate(payload.payload)
                end
                break
            end
        end
    end)

    EventSystem:listen(listener_id, EventSystem.Signal.ScorableStatesReset, function(payload)
        scoring_object_states = payload
    end)

    if ui.button("Save scoring objects") then
        ConfigIO.saveConfig(ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/scoring.json", scoring_object_states)
    end

    if ui.button("Load scoring objects") then
        scoring_object_states = ConfigIO.loadConfig(ac.getFolder(ac.FolderID.CurrentTrackLayout) .. "/scoring.json")
        EventSystem:emit(EventSystem.Signal.ScorableStatesReset, scoring_object_states)
    end
end

return Debug
