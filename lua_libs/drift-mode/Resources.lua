local Assert = require('drift-mode.assert')

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
    Colors = {
        Speed = rgbm(230 / 255, 138 / 255, 46 / 255, 1),
        Angle = rgbm(20 / 255, 204 / 255, 112 / 255, 1),
        Depth = rgbm(112 / 255, 20 / 255, 204 / 255, 1),
        NeutralSpeed = rgbm(148 / 255, 132 / 255, 122 / 255, 1),
        NeutralAngle = rgbm(120 / 255, 142 / 255, 125 / 255, 1),
        NeutralRatio = rgbm(102 / 255, 82 / 255, 106 / 255, 1),
        FaintBg = rgbm(1, 1, 1, 0.2),
        EditorInactivePoi = rgbm(1, 1, 1, 1),
        EditorActivePoi = rgbm(0, 1, 0, 1),
        EditorHighlightedPoi = rgbm(0, 0, 1, 1),
        ScoringObjectInactive = rgbm(0.1, 0.3, 1, 1),
        ScoringObjectActive = rgbm(0.05, 1, 0.05, 1),
        ScoringObjectDone = rgbm(0.5, 1, 0.1, 1),
        ScoringObjectBad = rgbm(0.8, 0.3, 0.3, 1),
        ScoringObjectGood = rgbm(0.3, 0.8, 0.3, 1),
        ScoringObjectOutside = rgbm(1, 0.2, 0.2, 1),
        Start = rgbm(0.2, 1, 0.2, 1),
        Finish = rgbm(0.2, 0.2, 1, 1),
        Respawn = rgbm(1, 0.2, 0.2, 1),
        RespawnPoint = rgbm(1, 0.2, 0.2, 1),
    },
}

return Resources
