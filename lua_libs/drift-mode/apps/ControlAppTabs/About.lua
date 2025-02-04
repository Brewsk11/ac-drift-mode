local About = {}

function About.drawUIAbout()
    ui.text("Visit project pages:")
    if ui.textHyperlink("RaceDepartment") then
        os.openURL("https://www.racedepartment.com/downloads/driftmode-competition-drift-gamemode.59863/")
    end
    if ui.textHyperlink("YouTube") then
        os.openURL("https://www.youtube.com/channel/UCzdi8sI1KxO7VXNlo_WaSAA")
    end
    if ui.textHyperlink("GitHub") then
        os.openURL("https://github.com/Brewsk11/ac-drift-mode")
    end
end

return About
