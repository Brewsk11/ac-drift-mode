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
    local hit = vec3()

    if physics.raycastTrack(point:value() + vec3(0, 10, 0), vec3(0, -1, 0), 500, hit) ~= -1 then
        point:set(hit)
        return hit
    end
end

return RaycastHelper
