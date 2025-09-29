local Models = require("drift-mode.models.init") -- TODO : For some reason does not work without init

local TestHarness = {}

function TestHarness:visitModel(model)
    if ClassBase.isInstanceOf(model) then
        -- An actual model definition
        self:__runTest(model)
    else
        -- A subtable with models, recurse into
        for _, models_subdirectory in pairs(model) do
            self:visitModel(models_subdirectory)
        end
    end
end

function TestHarness:__runTest(class)
    if class.test ~= nil then
        class.test()
    end
end

function TestHarness:runTesting()
    self:visitModel(Models)

    local classes_to_test = {
        Serializer = require('drift-mode.serializer')
    }

    for _, class in pairs(classes_to_test) do
        self:__runTest(class)
    end
end

return TestHarness
