local ModelBase = require("drift-mode.models.ModelBase")

---@class TestClassCustomSerializer : ModelBase
local TestClassCustomSerializer = class("TestClassCustomSerializer", ModelBase)
TestClassCustomSerializer.__model_path = "Tests.Serializer.CustomSerializerClass"

function TestClassCustomSerializer:initialize()
    ModelBase.initialize(self)
    self.number = math.random(1000)
end

function TestClassCustomSerializer:__serialize()
    return {
        custom_number = "abc" .. tostring(self.number) .. "def"
    }
end

function TestClassCustomSerializer.__deserialize(data)
    local obj = TestClassCustomSerializer()
    obj.number = tonumber(string.trim(data.custom_number, "abcdef"))
    return obj
end

return TestClassCustomSerializer
