local Point = require("drift-mode.models.Common.Point.Point")


local RaycastHelper = {}

function RaycastHelper.getTrackRayMouseHit()
    local hit = vec3(0, 0, 0)
    local ray = render.createMouseRay()

    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then
        return hit
    end
end

---Raycasts directly from above the point directly downwards
---and mutates the point such that it lays on the track.
---@param point Point
---@return vec3?
function RaycastHelper.alignPointToTrack(point)
    local aligned = RaycastHelper.getAlignedToTrack(point)
    if aligned then
        point:set(aligned)
    end
end

---@param point vec3|Point
---@return vec3?
function RaycastHelper.getAlignedToTrack(point)
    if not physics then
        ac.warn("Could not call RaycastHelper.alignPointToTrack() due to not available `physics`")
        return
    end

    local vec
    if Point.isInstanceOf(point) then
        vec = point:value()
    else
        vec = point
    end

    local hit = vec3()
    local dist = physics.raycastTrack(vec + vec3(0, 30, 0), vec3(0, -1, 0), 50, hit)
    if dist ~= -1 then
        return hit
    end
end

return RaycastHelper
