local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

-- Game state information

---@class GameState : ClassBase
---@field isTrackSetup boolean Is the car setup mode enabled
---@field isCarSetup boolean Is the track setup mode enabled
local GameState = class("GameState")

function GameState:initialize(is_car_setup, is_track_setup)
    self.isCarSetup = is_car_setup or false
    self.isTrackSetup = is_track_setup or false
end

function GameState:isPlaymode()
    return not self.isTrackSetup and not self.isCarSetup
end

local function test()
end
test()

return GameState
