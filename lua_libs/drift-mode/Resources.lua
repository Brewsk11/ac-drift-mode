local Assert = require('drift-mode/assert')

local gui_dir = ac.getFolder(ac.FolderID.Root) .. "/content/gui/drift-mode"

---@enum Resources
local Resources = {
    IconZoneWhite = gui_dir .. "/zone_icon_white.png",
    IconZoneBlack = gui_dir .. "/zone_icon_black.png",
    IconClipWhite = gui_dir .. "/clip_icon_white.png",
    IconClipBlack = gui_dir .. "/clip_icon_black.png",
    LogoWhite = gui_dir .. "/logo_white.png",
    EmblemInvertedFlat = gui_dir .. "/emblem_inverted_flat.png",
    EmblemFlat = gui_dir .. "/emblem_flat.png",
    TestTexture = gui_dir .. "/texture.png",
    ColorSpeed = rgbm(230 / 255, 138 / 255, 46 / 255, 1),
    ColorAngle = rgbm(20 / 255, 204 / 255, 112 / 255, 1),
    ColorDepth = rgbm(112 / 255, 20 / 255, 204 / 255, 1),
    ColorNeutralSpeed = rgbm(148 / 255, 132 / 255, 122 / 255, 1),
    ColorNeutralAngle = rgbm(120 / 255, 142 / 255, 125 / 255, 1),
    ColorNeutralRatio = rgbm(102 / 255, 82 / 255, 106 / 255, 1),
    ColorFaintBg = rgbm(1, 1, 1, 0.2),
    ColorEditorInactivePoi = rgbm(1, 1, 1, 0.5),
    ColorEditorActivePoi = rgbm(1, 1, 1, 1),
    ColorEditorHighlightedPoi = rgbm(3, 0, 0, 1),
}

return Resources
