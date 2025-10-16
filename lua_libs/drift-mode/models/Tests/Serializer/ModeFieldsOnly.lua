local ModelBase = require("drift-mode.models.ModelBase")

---@class ModeFieldsOnly : ModelBase
local TestClassSerializerModeFieldsOnly = class("TestClassSerializerModeFieldsOnly", ModelBase)
TestClassSerializerModeFieldsOnly.__model_path = "Tests.Serializer.ModeFieldsOnly"

function TestClassSerializerModeFieldsOnly:initialize()
    ModelBase:initialize()
    self.number = math.random(1000)
end

function TestClassSerializerModeFieldsOnly:__serialize()
    return {
        custom_number = "abc" .. tostring(self.number) .. "def"
    }
end

function TestClassSerializerModeFieldsOnly.__deserialize(data)
    local S = require('drift-mode.serializer')
    local obj = S.deserialize(data, S.Mode.FieldsVerbatim)

    obj.number = tonumber(string.trim(data.custom_number, "abcdef"))
    return obj
end

return TestClassSerializerModeFieldsOnly
