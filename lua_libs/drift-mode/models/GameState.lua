local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

-- Game state information

---@class GameState
---@field isTrackSetup boolean Is the car setup mode enabled
---@field isCarSetup boolean Is the track setup mode enabled
local GameState = {}
GameState.__index = GameState

function GameState.serialize(self)
    local data = {
        __class = "GameState",
        isCarSetup = S.serialize(self.isCarSetup),
        isTrackSetup = S.serialize(self.isTrackSetup),
    }

    return data
end

function GameState.deserialize(data)
    Assert.Equal(data.__class, "GameState", "Tried to deserialize wrong class")

    local obj = GameState.new()
    obj.isCarSetup = S.deserialize(data.isCarSetup)
    obj.isTrackSetup = S.deserialize(data.isTrackSetup)
    return obj
end

function GameState.new()
    local self = setmetatable({}, GameState)
    self.isCarSetup = false
    self.isTrackSetup = false
    return self
end

local function test()
end
test()

return GameState
