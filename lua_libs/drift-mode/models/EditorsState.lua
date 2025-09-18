local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

-- Game state information

---@class EditorsState : ClassBase
---@field isTrackSetup boolean Is the car setup mode enabled
---@field isCarSetup boolean Is the track setup mode enabled
local EditorsState = class("EditorsState")
EditorsState.__model_path = "EditorsState"

function EditorsState:initialize(is_car_setup, is_track_setup)
    self.isCarSetup = is_car_setup or false
    self.isTrackSetup = is_track_setup or false
end

function EditorsState:anyEditorEnabled()
    return self.isTrackSetup or self.isCarSetup
end

local function test()
end
test()

return EditorsState
