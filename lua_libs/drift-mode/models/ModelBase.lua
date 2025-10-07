---Base class for model classes that are expected to be serialized.
---@class ModelBase : ClassBase
local ModelBase = class("ModelBase", ClassBase)
ModelBase.__model_path = "ModelBase"

---@alias ModelDefinition {__name: string, __model_path: string, __deserialize: function|nil, __serialize: function|nil, test: function|nil}

---@type table<string, ModelDefinition>
ModelBase.PathToAbbrev = {}
ModelBase.AbbrevToPath = {}

---@overload fun()
---@overload fun(self: ModelBase)
function ModelBase:initialize()

end

function ModelBase:setModelPath(model_path)
end

function ModelBase:setAbbrev(abbrev)
end

function ModelBase:subclassed(classDefinition)
end

return ModelBase
