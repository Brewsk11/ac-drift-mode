---Base class for model classes that are expected to be serialized.
---@class ModelBase : ClassBase
local ModelBase = class("ModelBase", ClassBase)
ModelBase.__model_path = "ModelBase"


function ModelBase:subclassed(classDefinition)
end

---@alias ModelDefinition {__name: string, __model_path: string, __deserialize: function|nil, __serialize: function|nil, __post_deserialize: function|nil, test: function|nil}

return ModelBase
