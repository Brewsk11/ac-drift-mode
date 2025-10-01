local Assert = require('drift-mode/assert')
local json = require('drift-mode/json')

local ModelBase = require("drift-mode.models.ModelBase")

local Serializer = {}

---Serialize custom objects so that they can be encoded as JSON.
---
---ModelBase derived classes can have a `Class:__serialize()` method
---and `Class.__deserialize()` class function, that `Serializer.serialize()`
---and `Serializer.deserialize()` would use to de/serialize them.
---
---Custom classes that are not exported as a `require()`-able modules
---cannot have custom deserializer methods because deserializer method
---would not know how to find them.
---
---`ModelBase` abstracts that away, but serializable classes must inherit from it.
---@param data any
---@return any
function Serializer.serialize(data)
    if ClassBase.isInstanceOf(data) and not ModelBase.isInstanceOf(data) then
        Assert.Error("Cannot serialize ClassBase inherited class \"" ..
            data.__model_path .. "\", it needs to extend ModelBase!")
    end

    -- ModelBase class
    if ModelBase.isInstanceOf(data) then
        local obj = {}

        if data.__serialize == nil then
            -- Classes with no custom de/serializer
            for k, v in pairs(data) do
                obj[k] = Serializer.serialize(v)
            end
        else
            -- Classes with customized de/serializer
            Assert.Equal(type(data.__serialize), "function")

            obj = data:__serialize()
        end

        obj.__class = data.__model_path
        return obj
    end

    -- array
    if type(data) == 'table' and data[1] ~= nil then
        local new_data = {}
        for idx, val in ipairs(data) do
            new_data[idx] = Serializer.serialize(val)
        end
        return new_data
    end

    -- table
    if type(data) == 'table' then
        local new_data = { __table = true }
        for el, val in pairs(data) do
            new_data[el] = Serializer.serialize(val)
        end
        return new_data
    end

    -- vec2
    if vec2.isvec2(data) then
        return {
            __vec2 = true,
            x = data.x,
            y = data.y
        }
    end

    -- vec3
    if vec3.isvec3(data) then
        return {
            __vec3 = true,
            x = data.x,
            y = data.y,
            z = data.z
        }
    end

    -- rgbm & rgb
    if rgb.isrgb(data) or rgbm.isrgbm(data) then
        local color = {
            r = data.r,
            g = data.g,
            b = data.b
        }

        if rgbm.isrgbm(data) then
            color.__rgbm = true
            color.mult = data.mult
        else
            color.__rgb = true
        end

        return color
    end

    assert(
        type(data) == "nil" or
        type(data) == "number" or
        type(data) == "string" or
        type(data) == "boolean",
        "Serializing '" .. type(data) .. "' type is not implemented."
    )

    return { __val = data }
end

-- Map for migration from classes saved on v2.7.1 version and before
MAP_271_MIGRATION = {
    Drawer = "Drawers.Drawer",
    DrawerClip = "Drawers.DrawerClip",
    DrawerClipPlay = "Drawers.DrawerClipPlay",
    DrawerClipSetup = "Drawers.DrawerClipSetup",
    DrawerClipState = "Drawers.DrawerClipState",
    DrawerClipStatePlay = "Drawers.DrawerClipStatePlay",
    DrawerCourse = "Drawers.DrawerCourse",
    DrawerCoursePlay = "Drawers.DrawerCoursePlay",
    DrawerCourseSetup = "Drawers.DrawerCourseSetup",
    DrawerObjectEditorPoi = "Drawers.DrawerObjectEditorPoi",
    DrawerPoint = "Drawers.DrawerPoint",
    DrawerPointGroup = "Drawers.DrawerPointGroup",
    DrawerPointGroupConnected = "Drawers.DrawerPointGroupConnected",
    DrawerPointGroupSimple = "Drawers.DrawerPointGroupSimple",
    DrawerPointSimple = "Drawers.DrawerPointSimple",
    DrawerPointSphere = "Drawers.DrawerPointSphere",
    DrawerRunState = "Drawers.DrawerRunState",
    DrawerRunStatePlay = "Drawers.DrawerRunStatePlay",
    DrawerSegment = "Drawers.DrawerSegment",
    DrawerSegmentLine = "Drawers.DrawerSegmentLine",
    DrawerSegmentWall = "Drawers.DrawerSegmentWall",
    DrawerStartingPoint = "Drawers.DrawerStartingPoint",
    DrawerStartingPointSetup = "Drawers.DrawerStartingPointSetup",
    DrawerZone = "Drawers.DrawerZone",
    DrawerZonePlay = "Drawers.DrawerZonePlay",
    DrawerZoneSetup = "Drawers.DrawerZoneSetup",
    DrawerZoneState = "Drawers.DrawerZoneState",
    DrawerZoneStatePlay = "Drawers.DrawerZoneStatePlay",
    ObjectEditorPoi = "CourseEditor.POIs.ObjectEditorPoi",
    PoiClip = "CourseEditor.POIs.PoiClip",
    PoiSegment = "CourseEditor.POIs.PoiSegment",
    PoiStartingPoint = "CourseEditor.POIs.PoiStartingPoint",
    PoiZone = "CourseEditor.POIs.PoiZone",
    EditorRoutine = "CourseEditor.Routines.EditorRoutine",
    RoutineExtendPointGroup = "CourseEditor.Routines.RoutineExtendPointGroup",
    RoutineMovePoi = "CourseEditor.Routines.RoutineMovePoi",
    RoutineSelectSegment = "CourseEditor.Routines.RoutineSelectSegment",
    Point = "Common.Point",
    PointGroup = "Common.PointGroup",
    Segment = "Common.Segment",
    SegmentGroup = "Common.SegmentGroup",
    CarConfig = "Editor.CarConfig",
    TrackConfigInfo = "TrackObjects.Course.TrackConfigInfo",
    TrackConfig = "TrackObjects.Course.TrackConfig",
    RunState = "TrackObjects.Course.RunState",
}

local M = nil

---Given "Some.Path.Class" return its class definition.
---@param model_path string
---@return ModelDefinition
function Serializer.getModelDefinition(model_path)
    if M == nil then
        M = require('drift-mode.models.init') -- TODO : For some reason does not work without init
    end

    local parts = {}

    if MAP_271_MIGRATION[model_path] ~= nil then
        model_path = MAP_271_MIGRATION[model_path]
    end

    -- Split on '.'
    for part in string.gmatch(model_path, "([^.]+)") do
        parts[#parts + 1] = part
    end

    local obj = M
    for _, part in ipairs(parts) do
        obj = obj[part]
        Assert.NotEqual(type(obj), "nil",
            "Can't find model for path: \"" .. model_path .. "\", missing part:'" .. part .. "'")
    end

    --Assert.True(type(obj) == "function", "Invalid model_path: '" .. model_path .. "' is not a class constructor")
    return obj
end

---Use it to deserialize previously serialized data
---@param data any
---@return any
function Serializer.deserialize(data)
    -- nil
    if data == nil then return nil end

    -- ModelBase classes
    if data['__class'] ~= nil then
        local obj = nil

        local ModelClass = Serializer.getModelDefinition(data.__class)

        -- Classes inheirting from ModelBase
        -- can have custom serializers
        if ModelClass.__deserialize == nil then
            -- Classes with no custom deserializer
            obj = ModelClass()
            for k, v in pairs(data) do
                obj[k] = Serializer.deserialize(v)
            end
        else
            -- Classes with customized deserializer
            Assert.Equal(type(ModelClass.__deserialize), "function")
            obj = ModelClass.__deserialize(data)
        end

        return obj
    end

    -- table
    if data['__table'] ~= nil then
        local new_data = {}
        for el, val in pairs(data) do
            if not string.startsWith(el, '__') then
                new_data[el] = Serializer.deserialize(val)
            end
        end
        return new_data
    end

    -- array
    if type(data) == 'table' and data[1] ~= nil then
        local new_data = {}
        data.__array = nil
        for idx, val in ipairs(data) do
            new_data[idx] = Serializer.deserialize(val)
        end
        return new_data
    end

    -- vec2
    if data['__vec2'] ~= nil then
        return vec2(data.x, data.y)
    end

    -- vec3
    if data['__vec3'] ~= nil then
        return vec3(data.x, data.y, data.z)
    end

    -- rgbm & rgb
    if data['__rgb'] ~= nil then return rgb(data.r, data.g, data.b) end
    if data['__rgbm'] ~= nil then return rgbm(data.r, data.g, data.b, data.mult) end

    return data.__val
end

function Serializer.toJson(data)
    return json.encode(Serializer.serialize(data))
end

function Serializer.checkEqual(prefix, obj_a, obj_b, debug)
    if type(obj_a) ~= "table" and type(obj_b) ~= "table" then
        if debug then ac.log("`" .. prefix .. "` : " .. tostring(obj_a) .. " vs. " .. tostring(obj_b)) end
        return obj_a == obj_b, obj_a, obj_b
    elseif type(obj_a) == "table" and type(obj_b) == "table" then
        for k, v in pairs(obj_a) do
            local res, _obj_a, _obj_b = Serializer.checkEqual(prefix .. "." .. k, v, obj_b[k], debug)
            if not res then
                return res, _obj_a, _obj_b
            end
        end
    else
        if debug then ac.log(tostring(obj_a) .. " ~= " .. tostring(tostring(obj_b))) end
        return false, obj_a, obj_b
    end
    return true, obj_a, obj_b
end

function Serializer.test()
    local TestClass = require("drift-mode.models.Tests.Serializer.MainClass")
    local TestClassCustomSerializer = require("drift-mode.models.Tests.Serializer.CustomSerializerClass")

    local c = TestClass()
    c.string = "changed"
    c.nested_table.string = "changed_nested"

    local test_payload = {
        ctype_vec3 = vec3(1, 2, 3),
        string = "abc",
        number = 123,
        boolean = true,
        nil_value = nil,
        simple_table = {
            number = 1,
            string = '2'
        },
        array = { "a", "b" },
        class = c,
        class_custom_serializer = TestClassCustomSerializer()
    }

    local serialized = Serializer.serialize(test_payload)
    local deserialized = Serializer.deserialize(serialized)

    local res, obj_a, obj_b = Serializer.checkEqual("test_payload", test_payload, deserialized, false)
    Assert.True(res, "Serialization faled at: `" .. tostring(obj_a) .. "` vs. `" .. tostring(obj_b) .. "`\n")
end

return Serializer
