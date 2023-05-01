local DataBroker = require('drift-mode/databroker')
local EventSystem = require('drift-mode/eventsystem')
require('drift-mode/models')

local json = require('drift-mode/json')

local AsyncHelper = {}

---comment
---@return Cursor
local function loadCursor()
    return DataBroker.read("cursor_data")
end

local function updateCursor(cursor_data)
    DataBroker.store("cursor_data", cursor_data)
    EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function AsyncHelper.runTask(task)
    while true do
        local res = task()
        if res ~= nil then return res end
        coroutine.yield()
    end
end

local function waitForRelease(key_index)
    AsyncHelper.runTask(function()
        if ui.keyboardButtonReleased(key_index) then
            return true
        end
    end)
end

local function pressed(key_index)
    if ui.keyboardButtonDown(key_index) then
        waitForRelease(key_index)
        return true
    end
    return false
end

local function select()
    return pressed(ui.KeyIndex.S)
end

local function finish()
    return pressed(ui.KeyIndex.F)
end

local function cancel()
    return pressed(ui.KeyIndex.A)
end

local function back()
    return pressed(ui.KeyIndex.Q)
end

function AsyncHelper.taskTrackRayHit()
    local hit = vec3(0, 0, 0)
    local ray = render.createMouseRay()

    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then
        return hit
    end
end

function AsyncHelper.taskGatherPointGroup()
    local group = PointGroup.new()

    local c = loadCursor()
    c.point_group_a = group
    updateCursor(c)

    local retval = nil
    while true do
        local hit = AsyncHelper.runTask(AsyncHelper.taskTrackRayHit)

        if select() then group:append(Point.new("test", hit)) end
        if finish() then retval = group; break end
        if cancel() then retval = false; break end
        if back() and group:count() > 0 then
            group:pop()
        end

        local c = loadCursor()
        c.point_group_a = group
        c.selector = Point.new("", hit)
        updateCursor(c)

        coroutine.yield()
    end

    local c = loadCursor()
    c.point_group_a = nil
    c.selector = nil
    updateCursor(c)

    return retval
end

function AsyncHelper.taskGatherPoint()
    local hit = AsyncHelper.runTask(AsyncHelper.taskTrackRayHit)

    local c = loadCursor()
    c.selector = Point.new("", hit)
    updateCursor(c)

    if select() then
        local c = loadCursor()
        c.selector = nil
        updateCursor(c)
        return Point.new("", hit)
    end

    if cancel() then return false end
    coroutine.yield()
end

return AsyncHelper