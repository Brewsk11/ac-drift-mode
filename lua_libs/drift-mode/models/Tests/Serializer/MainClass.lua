local ModelBase = require("drift-mode.models.ModelBase")
local TestClassNested = require("drift-mode.models.Tests.Serializer.NestedClass")

---@class TestClass : ModelBase
local TestClass = class("TestClass", ModelBase)
TestClass.__model_path = "Tests.Serializer.MainClass"

function TestClass:initialize()
    self.number = math.random(1000)
    self.string = "from_initialize"
    self.nested_table = { string = 'from_initialize_nested', table = { number = math.random(1000), float = math.random() } }
    self.nested_class = TestClassNested()
    self.nested_class_array = {}
    for i = 1, 2 do
        self.nested_class_array[#self.nested_class_array + 1] = TestClassNested()
    end
end

return TestClass
