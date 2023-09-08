local Assert = require('drift-mode/assert')
local S = require('drift-mode/serializer')

local Zone = require('drift-mode/models/Zone')
local WorldObject = require('drift-mode/models/WorldObject')

-- Track configration data

---@class TrackConfig : WorldObject
---@field name string Configuration name
---@field scoringObjects ScoringObject[]
---@field startLine Segment
---@field respawnLine Segment
---@field finishLine Segment
---@field startingPoint StartingPoint
---@field scoringRanges ScoringRanges
local TrackConfig = class("TrackConfig", WorldObject)

function TrackConfig:initialize(name, scoringObjects, startLine, finishLine, respawnLine, startingPoint, scoringRanges)
    self.name = name or 'default'
    self.scoringObjects = scoringObjects or {}
    self.startLine = startLine
    self.finishLine = finishLine
    self.respawnLine = respawnLine
    self.startingPoint = startingPoint
    self.scoringRanges = scoringRanges or ScoringRanges(Range(15, 50), Range(5, 45))
    self:setDrawer(DrawerCourseSetup())
end

function TrackConfig:serialize()
    local data = {
        __class = "TrackConfig",
        name = S.serialize(self.name),
        scoringObjects = {},
        startLine = S.serialize(self.startLine),
        finishLine  = S.serialize(self.finishLine),
        respawnLine  = S.serialize(self.respawnLine),
        startingPoint = S.serialize(self.startingPoint),
        scoringRanges = S.serialize(self.scoringRanges)
    }

    for idx, scoringObject in ipairs(self.scoringObjects) do
        if Zone.isInstanceOf(scoringObject) then
            data.scoringObjects[idx] = Zone.serialize(scoringObject)
        elseif Clip.isInstanceOf(scoringObject) then
            data.scoringObjects[idx] = Clip.serialize(scoringObject)
        end
    end

    return data
end

function TrackConfig.deserialize(data)
    Assert.Equal(data.__class, "TrackConfig", "Tried to deserialize wrong class")

    local obj = TrackConfig()

    -- 2.1.0 compatibility transfer
    --   Changed `clippingPoints` field name to `clips`
    if data.clippingPoints ~= nil then data.clips = data.clippingPoints end
    --   Added new field `scoringRanges`; if nil then fill default
    if S.deserialize(data.scoringRanges) == nil then
        data.scoringRanges = S.serialize(
            ScoringRanges(Range(15, 50), Range(5, 45))
        )
    end

    -- 2.3.1 compatibility transfer
    --   Migrated zones and clips to ScoringObjects
    if data.zones or data.clips then
        local scoringObjects = {}
        for _, zone in ipairs(data.zones) do
            scoringObjects[#scoringObjects+1] = zone
        end
        for _, clip in ipairs(data.clips) do
            scoringObjects[#scoringObjects+1] = clip
        end
        data.scoringObjects = scoringObjects
    end

    local scoringObjects = {}
    for idx, scoringObject in ipairs(data.scoringObjects) do
        if scoringObject.__class == Zone.__name then
            scoringObjects[idx] = Zone.deserialize(scoringObject)
        elseif scoringObject.__class == Clip.__name then
            scoringObjects[idx] = Clip.deserialize(scoringObject)
        else
            Assert.Error("Some ScoringObject was neither Zone or Clip")
        end
    end
    obj.scoringObjects = scoringObjects

    obj.name = S.deserialize(data.name)
    obj.startLine = S.deserialize(data.startLine)
    obj.finishLine = S.deserialize(data.finishLine)
    obj.respawnLine = S.deserialize(data.respawnLine)
    obj.startingPoint = S.deserialize(data.startingPoint)
    obj.scoringRanges = S.deserialize(data.scoringRanges)
    return obj
end

function TrackConfig:getNextZoneName()
    return "zone_" .. string.format('%03d', #self.scoringObjects + 1)
end

function TrackConfig:getNextClipName()
    return "clip_" .. string.format('%03d', #self.scoringObjects + 1)
end

function TrackConfig:gatherColliders()
    local colliders = {}
    for _, obj in ipairs(self.scoringObjects) do
        if obj.isInstanceOf(Zone) then
            colliders = table.chain(colliders, obj:gatherColliders())
        end
    end
    return colliders
end

local function test()
end
test()

return TrackConfig
