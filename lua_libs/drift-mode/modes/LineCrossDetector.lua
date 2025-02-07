local EventSystem = require('drift-mode/eventsystem')
local listener_id = EventSystem.registerListener("mode-linecrossdetector")

local LineCrossDetector = {}
-- The line detector projects Points to vec2 on XZ plane


local registeredLines = {}

function LineCrossDetector.registerLine(segment, signal, maxDelta)
    registeredLines[#registeredLines + 1] = {
        segment = segment,
        signal = signal,
        maxDelta = maxDelta
    }
end

function LineCrossDetector.clear()
    registeredLines = {}
end

---@type Point
local last_point = nil

function LineCrossDetector.registerPoint(point)
    if last_point == nil then
        last_point = point
        return
    end

    for _, v in ipairs(registeredLines) do
        -- Moving more than 1 meter per frame is definitely a teleport.
        -- In such cases skip the comparison.
        local delta = last_point:flat():distance(point:flat())

        if delta > v.maxDelta then
            last_point = point
            goto continue
        end

        local res = vec2.intersect(
            v.segment.head:flat(),
            v.segment.tail:flat(),
            last_point:flat(),
            point:flat()
        )
        if res then
            EventSystem.emit(v.signal, {})
        end
        ::continue::
    end

    last_point = point
end

return LineCrossDetector
