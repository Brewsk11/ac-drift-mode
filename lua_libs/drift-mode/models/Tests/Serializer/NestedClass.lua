local ModelBase = require("drift-mode.models.ModelBase")

---@class TestClassNested : ModelBase
local TestClassNested = class("TestClassNested", ModelBase)
TestClassNested.__model_path = "Tests.Serializer.NestedClass"

function TestClassNested:initialize()
    ModelBase.initialize(self)
    self.number = math.random(1000)
    self.string = "from_initialize"
    self.nested_table = { table = { number = math.random(1000), float = math.random() } }
end

return TestClassNested
