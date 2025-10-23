local CameraHelper = {}

---@type ac.GrabbedCamera?
local camera = nil

function CameraHelper.grabCamera(reason)
    if camera ~= nil then
        ac.warn("Camera already grabbed")
    else
        camera = ac.grabCamera(reason)
    end
end

function CameraHelper.isGrabbed()
    return camera ~= nil
end

function CameraHelper.setCamera(position, side, look, fov)
    if camera == nil then
        ac.warn("Camera is nil")
        return
    end

    camera.transform.look:set(look)
    camera.transform.side:set(side)
    camera.transform.position:set(position)
    camera.fov = fov
end

function CameraHelper.disposeCamera()
    if camera == nil then
        ac.warn("Camera is nil")
        return
    end

    camera:dispose()
    camera = nil
end

return CameraHelper
