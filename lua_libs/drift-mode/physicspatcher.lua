local Assert = require('drift-mode/assert')

local PhysicsPatcher = {}

PhysicsPatcher.PATCH_TAG_BEGIN = '; DRIFT_MODE_PATCH_BEGIN'
PhysicsPatcher.PATCH_TAG_END   = '; DRIFT_MODE_PATCH_END'

PhysicsPatcher.PATCH_CONTENT = "\n\n" .. PhysicsPatcher.PATCH_TAG_BEGIN .. [[

[SURFACE_0]
WAV_PITCH=extended-0

[_SCRIPTING_PHYSICS]
ALLOW_APPS=1
]] .. PhysicsPatcher.PATCH_TAG_END

function PhysicsPatcher.getSurfacesPath()
    local layout_subpath = ac.getTrackLayout()
    if layout_subpath ~= "" then layout_subpath = "\\" .. layout_subpath end
    return ac.getFolder(ac.FolderID.ContentTracks) .. "\\" .. ac.getTrackID() .. layout_subpath .. "\\data\\surfaces.ini"
end

function PhysicsPatcher.getSurfacesBackupPath()
    local layout_subpath = ac.getTrackLayout()
    if layout_subpath ~= "" then layout_subpath = "\\" .. layout_subpath end
    return ac.getFolder(ac.FolderID.ContentTracks) .. "\\" .. ac.getTrackID() .. layout_subpath .. "\\data\\surfaces.driftmode_patch_backup.ini"
end

function PhysicsPatcher.backupExists()
    return io.exists(PhysicsPatcher.getSurfacesBackupPath())
end

local patched = false
local function checkPatched()
    for line in io.lines(PhysicsPatcher.getSurfacesPath()) do
        if line == PhysicsPatcher.PATCH_TAG_BEGIN then return true end
    end
    return false
end
patched = checkPatched()

function PhysicsPatcher.isPatched()
    return patched
end

function PhysicsPatcher.backupSurfaces()
    local og_file = io.open(PhysicsPatcher.getSurfacesPath(), "r")
    Assert.NotEqual(og_file, nil, "Could not open " .. PhysicsPatcher.getSurfacesPath() .. " file")

    local back_file = io.open(PhysicsPatcher.getSurfacesBackupPath(), "w")
    Assert.NotEqual(back_file, nil, "Could not open " .. PhysicsPatcher.getSurfacesBackupPath() .. " file")

    back_file:write(og_file:read("a"))

    back_file:close()
    og_file:close()

    patched = checkPatched()
end

function PhysicsPatcher.patch()
    Assert.Equal(PhysicsPatcher.isPatched(), false, "Trying to patch already patched track")

    PhysicsPatcher.backupSurfaces()

    local surfaces_file = io.open(PhysicsPatcher.getSurfacesPath(), "a")
    surfaces_file:write(PhysicsPatcher.PATCH_CONTENT)
    surfaces_file:close()

    patched = checkPatched()
end

function PhysicsPatcher.restore()
    local back_file = io.open(PhysicsPatcher.getSurfacesBackupPath(), "r")
    Assert.NotEqual(back_file, nil, "Could not open " .. PhysicsPatcher.getSurfacesBackupPath() .. " file")

    local og_file = io.open(PhysicsPatcher.getSurfacesPath(), "w")
    Assert.NotEqual(og_file, nil, "Could not open " .. PhysicsPatcher.getSurfacesPath() .. " file")

    og_file:write(back_file:read("a"))

    og_file:close()
    back_file:close()

    io.deleteFile(PhysicsPatcher.getSurfacesBackupPath())

    patched = checkPatched()
end

return PhysicsPatcher
