local Resources = require("drift-mode.Resources")

local About = {}

local function clickableImage(img_source, img_size, dest_url, caption)
    ui.image(img_source, img_size, ui.ImageFit.Fit)

    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        ui.setTooltip(caption)
    end

    if ui.itemClicked() then
        os.openURL(dest_url)
    end
end

function About.drawUIAbout()
    local logo_height = 150

    ui.image(Resources.EmblemInvertedFlat, vec2(ui.availableSpaceX(), logo_height), ui.ImageFit.Fit)

    local image_height = 50
    local image_width = 50

    ui.text("Visit project pages:")

    ui.offsetCursorY(20)

    clickableImage(
        "https://www.overtake.gg/data/files/logos/cropped-favicon-270x270.png",
        vec2(image_width, image_height),
        "https://www.overtake.gg/downloads/driftmode.59863/",
        "overtake.gg"
    )

    ui.offsetCursorX(image_width + 20)
    ui.offsetCursorY(-image_height - 4)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(0, image_height), rgbm(1, 1, 1, 0.2), 1)
    ui.offsetCursorX(20)

    clickableImage(
        "https://icones.pro/wp-content/uploads/2021/06/icone-github-grise.png",
        vec2(image_width, image_height),
        "https://github.com/Brewsk11/ac-drift-mode/blob/" .. Resources.Version .. "/README.md",
        "GitHub"
    )

    ui.offsetCursorX((image_width + 10) * 2 + 40)
    ui.offsetCursorY(-image_height - 4)
    ui.drawLine(ui.getCursor(), ui.getCursor() + vec2(0, image_height), rgbm(1, 1, 1, 0.2), 1)
    ui.offsetCursorX(20)

    clickableImage(
        "https://upload.wikimedia.org/wikipedia/commons/e/ef/Youtube_logo.png",
        vec2(image_width, image_height),
        "https://www.youtube.com/@MrBrew0",
        "YouTube"
    )
end

return About
