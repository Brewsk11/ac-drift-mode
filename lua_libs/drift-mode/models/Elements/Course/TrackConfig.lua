local Resources = require('drift-mode.Resources')

local ModelBase = require('drift-mode.models.ModelBase')
local ScoringRanges = require("drift-mode.models.Elements.Scorables.ScoringRanges")
local Range = require("drift-mode.models.Range")
local Point = require("drift-mode.models.Common.Point.Point")
local Segment = require("drift-mode.models.Common.Segment.Segment")

local Gate = require("drift-mode.models.Elements.Gate.Gate")


-- Track configration data

---@class TrackConfig : ModelBase
---@field name string Configuration name
---@field scorables Scorable[]
---@field startLine Gate
---@field respawnLine Gate
---@field finishLine Gate
---@field startingPoint Position
---@field scoringRanges ScoringRanges
local TrackConfig = class("TrackConfig", ModelBase)
TrackConfig.__model_path = "Elements.Course.TrackConfig"


function TrackConfig:initialize(name, scorables, startLine, finishLine, respawnLine, startingPoint, scoringRanges)
    ModelBase.initialize(self)

    self.name = name or 'default'
    self.scorables = scorables or {}

    self:setStartLine(startLine)
    self:setFinishLine(finishLine)
    self:setRespawnLine(respawnLine)
    self:setStartingPoint(startingPoint)

    self.scoringRanges = scoringRanges or ScoringRanges(Range(15, 50), Range(5, 45))

    self:cacheMethod("gatherHandles")
end

function TrackConfig:setDirty()
    ModelBase.setDirty(self)
    for _, scorable in ipairs(self.scorables) do
        scorable:setDirty()
    end
    if self.startLine then self.startLine:setDirty() end
    if self.finishLine then self.finishLine:setDirty() end
    if self.respawnLine then self.respawnLine:setDirty() end
    if self.startingPoint then self.startingPoint:setDirty() end
end

---2.7.1 migration
function TrackConfig.__deserialize(data)
    local S = require('drift-mode.serializer')

    -- Use FieldsVerbatim so that deserialize() call ignores this __deserialize() method
    -- avoiding circural call.
    local obj = S.deserialize(data, S.Mode.FieldsVerbatim)
    if obj.scoringObjects ~= nil then
        obj.scorables = obj.scoringObjects
    end

    if Segment.isInstanceOf(obj.startLine) then
        obj.startLine = Gate("Start line", obj.startLine)
    end

    if Segment.isInstanceOf(obj.finishLine) then
        obj.finishLine = Gate("Finish line", obj.finishLine)
    end

    if Segment.isInstanceOf(obj.respawnLine) then
        obj.respawnLine = Gate("Respawn line", obj.respawnLine)
    end

    return obj
end

function TrackConfig:getNextZoneName()
    return "zone_" .. string.format('%03d', #self.scorables + 1)
end

function TrackConfig:getNextClipName()
    return "clip_" .. string.format('%03d', #self.scorables + 1)
end

function TrackConfig:appendScorable(scorable)
    self.scorables[#self.scorables + 1] = scorable
    self:setDirty()
end

function TrackConfig:gatherColliders()
    local colliders = {}
    for _, obj in ipairs(self.scorables) do
        colliders = table.chain(colliders, obj:gatherColliders())
    end
    return colliders
end

---@return Handle[]
function TrackConfig:gatherHandles()
    local handles = {}

    local table_concat = function(t1, t2)
        for _, item in ipairs(t2) do
            t1[#t1 + 1] = item
        end
    end

    for _, obj in ipairs(self.scorables) do
        table_concat(handles, obj:gatherHandles())
    end

    if self.startLine then
        table_concat(handles, self.startLine:gatherHandles())
    end

    if self.finishLine then
        table_concat(handles, self.finishLine:gatherHandles())
    end

    if self.respawnLine then
        table_concat(handles, self.respawnLine:gatherHandles())
    end

    if self.startingPoint then
        table_concat(handles, self.startingPoint:gatherHandles())
    end

    return handles
end

function TrackConfig:getBoundingBox(padding)
    local changed = false

    local pMin = vec3(9999, 9999, 9999)
    local pMax = vec3(-9999, -9999, -9999)

    for _, obj in ipairs(self.scorables) do
        local obj_bounding_box = obj:getBoundingBox()

        if obj_bounding_box == nil then
            goto continue
        end

        pMin:min(obj_bounding_box.p1:value())
        pMax:max(obj_bounding_box.p2:value())
        changed = true

        ::continue::
    end

    if self.startLine and self.startLine.segment then
        pMin:min(self.startLine.segment:getHead():value())
        pMax:max(self.startLine.segment:getHead():value())
        pMin:min(self.startLine.segment:getTail():value())
        pMax:max(self.startLine.segment:getTail():value())
        changed = true
    end

    if self.finishLine and self.finishLine.segment then
        pMin:min(self.finishLine.segment:getHead():value())
        pMax:max(self.finishLine.segment:getHead():value())
        pMin:min(self.finishLine.segment:getTail():value())
        pMax:max(self.finishLine.segment:getTail():value())
        changed = true
    end

    if self.respawnLine and self.respawnLine.segment then
        pMin:min(self.respawnLine.segment:getHead():value())
        pMax:max(self.respawnLine.segment:getHead():value())
        pMin:min(self.respawnLine.segment:getTail():value())
        pMax:max(self.respawnLine.segment:getTail():value())
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

---@param gate Gate
function TrackConfig:setStartLine(gate)
    self.startLine = gate
    self:setDirty()
end

---@param gate Gate
function TrackConfig:setFinishLine(gate)
    self.finishLine = gate
    self:setDirty()
end

---@param gate Gate
function TrackConfig:setRespawnLine(gate)
    self.respawnLine = gate
    self:setDirty()
end

---@param position Position
function TrackConfig:setStartingPoint(position)
    self.startingPoint = position
    self:setDirty()
end

function TrackConfig:drawFlat(coord_transformer, scale)
    for _, obj in ipairs(self.scorables) do
        obj:drawFlat(coord_transformer, scale)
    end
    if self.startLine and self.startLine.segment then
        self.startLine.segment:drawFlat(coord_transformer, scale,
            Resources.Colors.Start)
    end
    if self.finishLine and self.finishLine.segment then
        self.finishLine.segment:drawFlat(coord_transformer, scale,
            Resources.Colors.Finish)
    end
    if self.respawnLine and self.respawnLine.segment then
        self.respawnLine.segment:drawFlat(coord_transformer, scale,
            Resources.Colors.Respawn)
    end
    if self.startingPoint then self.startingPoint:drawFlat(coord_transformer, scale, Resources.Colors.Respawn) end
end

local function test()
end
test()

return TrackConfig
