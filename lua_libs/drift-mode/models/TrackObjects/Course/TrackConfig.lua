local Resources = require('drift-mode/Resources')

local ModelBase = require('drift-mode.models.ModelBase')
local ScoringRanges = require("drift-mode.models.TrackObjects.ScoringObject.ScoringRanges")
local Range = require("drift-mode.models.Range")
local Point = require("drift-mode.models.Common.Point")

-- Track configration data

---@class TrackConfig : ModelBase
---@field name string Configuration name
---@field scoringObjects ScoringObject[]
---@field startLine Segment
---@field respawnLine Segment
---@field finishLine Segment
---@field startingPoint StartingPoint
---@field scoringRanges ScoringRanges
local TrackConfig = class("TrackConfig", ModelBase)
TrackConfig.__model_path = "TrackObjects.Course.TrackConfig"


function TrackConfig:initialize(name, scoringObjects, startLine, finishLine, respawnLine, startingPoint, scoringRanges)
    self.name = name or 'default'
    self.scoringObjects = scoringObjects or {}
    self.startLine = startLine
    self.finishLine = finishLine
    self.respawnLine = respawnLine
    self.startingPoint = startingPoint
    self.scoringRanges = scoringRanges or ScoringRanges(Range(15, 50), Range(5, 45))
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
        colliders = table.chain(colliders, obj:gatherColliders())
    end
    return colliders
end

function TrackConfig:getBoundingBox(padding)
    local changed = false

    local pMin = vec3(9999, 9999, 9999)
    local pMax = vec3(-9999, -9999, -9999)

    for _, obj in ipairs(self.scoringObjects) do
        local obj_bounding_box = obj:getBoundingBox()

        if obj_bounding_box == nil then
            goto continue
        end

        pMin:min(obj_bounding_box.p1:value())
        pMax:max(obj_bounding_box.p2:value())
        changed = true

        ::continue::
    end

    if self.startLine then
        pMin:min(self.startLine.head:value())
        pMax:max(self.startLine.head:value())
        pMin:min(self.startLine.tail:value())
        pMax:max(self.startLine.tail:value())
        changed = true
    end

    if self.finishLine then
        pMin:min(self.finishLine.head:value())
        pMax:max(self.finishLine.head:value())
        pMin:min(self.finishLine.tail:value())
        pMax:max(self.finishLine.tail:value())
        changed = true
    end

    if self.respawnLine then
        pMin:min(self.respawnLine.head:value())
        pMax:max(self.respawnLine.head:value())
        pMin:min(self.respawnLine.tail:value())
        pMax:max(self.respawnLine.tail:value())
        changed = true
    end

    if self.startingPoint then
        pMin:min(self.startingPoint.origin:value())
        pMax:max(self.startingPoint.origin:value())
        changed = true
    end

    if changed then
        return {
            p1 = Point(pMin - vec3(padding, padding, padding)),
            p2 = Point(pMax + vec3(padding, padding, padding))
        }
    else
        return nil
    end
end

function TrackConfig:drawFlat(coord_transformer, scale)
    for _, obj in ipairs(self.scoringObjects) do
        obj:drawFlat(coord_transformer, scale)
    end

    if self.startLine then self.startLine:drawFlat(coord_transformer, scale, Resources.Colors.Start) end
    if self.finishLine then self.finishLine:drawFlat(coord_transformer, scale, Resources.Colors.Finish) end
    if self.respawnLine then self.respawnLine:drawFlat(coord_transformer, scale, Resources.Colors.Respawn) end
    if self.startingPoint then self.startingPoint:drawFlat(coord_transformer, scale, Resources.Colors.Respawn) end
end

local function test()
end
test()

return TrackConfig
