local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.Assert')

---@class Element : ModelBase
---@field private name string
---@field private id string
local Element = class("ScoringObject", ModelBase)
Element.__model_path = "Elements.Element"

function Element:initialize(name)
    ModelBase.initialize(self)
    self.name = name
    self.id = Element.generateId()
end

local charset = "abcdefghijklmnopqrstuvwxyz1234567890"
local function randomString(length)
    local result = {}
    for _ = 1, length do
        local idx = math.random(1, #charset)
        table.insert(result, charset:sub(idx, idx))
    end
    return table.concat(result)
end

---@return string
---@private
function Element.generateId()
    return randomString(8)
end

---@return string
function Element:getId()
    return self.id
end

---@param id string
function Element:setId(id)
    self.id = id
end

---@return string
function Element:getName()
    return self.name
end

---@param name string
function Element:setName(name)
    self.name = name
end

---Get visual center of the object.
---Used mainly for visualization, so doesn't need to be accurate.
function Element:getCenter()
    Assert.Error("Called abstract method!")
end

---@return physics.ColliderType[]
function Element:gatherColliders()
    Assert.Error("Called abstract method!")
    return {}
end

---Draw itself using ui.* calls
---@param coord_transformer fun(Point): vec2 Function converting true coordinate to canvas coordinate
---@param scale number
function Element:drawFlat(coord_transformer, scale)
    Assert.Error("Called abstract method!")
end

function Element:getBoundingBox()
    Assert.Error("Called abstract method!")
end

---@return { [HandleId] : Handle }
function Element:gatherHandles()
    Assert.Error("Not implemented!")
    return {}
end

local function test()
end
test()

return class.emmy(Element, Element.initialize)
