local AsyncHelper = {}

function AsyncHelper.taskTrackRayHit()
    local hit = vec3(0, 0, 0)
    local ray = render.createMouseRay()

    if physics.raycastTrack(ray.pos, ray.dir, ray.length, hit) ~= -1 then
        return hit
    end
end

return AsyncHelper
