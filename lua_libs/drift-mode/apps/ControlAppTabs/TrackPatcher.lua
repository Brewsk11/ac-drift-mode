local PP = require('drift-mode/physicspatcher')

local TrackPatcher = {}

function TrackPatcher.drawUITrackPatcher()
    -- [BUTTON] Track patch button
    local patch_button_label = "Patch track"
    if PP.isPatched() then patch_button_label = "Unpatch track" end
    if ui.button(patch_button_label, vec2(ui.availableSpaceX(), 60)) then
        if PP.isPatched() then
            PP.restore()
            ac.setMessage("Removed track patch successfully", "")
        else
            PP.patch()
            ac.setMessage("Track patched successfully", "Please restart the game to enable extended physics.")
        end
    end
    ui.offsetCursorY(8)

    local patch_button_label = "Show file to patch"
    if ui.button(patch_button_label, vec2(ui.availableSpaceX(), 30)) then
        os.showInExplorer(PP.getSurfacesPath())
    end
    ui.offsetCursorY(15)

    -- [DECORATIVE] Track patching help text
    local help_text = [[
Functionality requiring patched track:
  - teleportation
  - zone collision

After patching the track restart the game.

Patched tracks may prevent joining online servers, as the local track version would be different than the one on the server.

Patcher modifies surfaces.ini file to enable extended physics.

More information on extended track physics in:]]
    ui.dwriteTextAligned(help_text, 14, -1, -1, vec2(ui.availableSpaceX(), 0), true)

    if ui.textHyperlink("CSP SDK documentation") then
        os.openURL("https://github.com/ac-custom-shaders-patch/acc-lua-sdk/blob/main/common/ac_physics.lua#L7")
    end
end

return TrackPatcher
