RealSonar = {}
RealSonar.Path = table.pack(...)[1]

dofile(RealSonar.Path .. "/Lua/functions.lua")
dofile(RealSonar.Path .. "/Lua/hulldetection.lua")

if SERVER then return end

local easySettings = dofile(RealSonar.Path .. "/Lua/easysettings.lua")
RealSonar.Settings = easySettings.LoadTable(RealSonar.Path .. "/settings.json")

easySettings.AddMenu("Real Sonar Settings", function (parent)
    local list = easySettings.BasicList(parent)
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), "Sonar Ping Volume", nil, nil, GUI.Alignment.Center)

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Settings.AirPingVolume = value
        textBlock.Text = string.format("Air Ping Volume %s%%", math.floor(value * 100))
        easySettings.SaveTable(RealSonar.Path .. "/settings.json", RealSonar.Settings)
    end, RealSonar.Settings.AirPingVolume)
    textBlock.Text = string.format("Air Ping Volume %s%%", math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Settings.WaterPingVolume = value
        textBlock.Text = string.format("Water Ping Volume %s%%", math.floor(value * 100))
        easySettings.SaveTable(RealSonar.Path .. "/settings.json", RealSonar.Settings)
    end, RealSonar.Settings.WaterPingVolume)
    textBlock.Text = string.format("Water Ping Volume %s%%", math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Settings.SuitPingVolume = value
        textBlock.Text = string.format("Suit Ping Volume %s%%", math.floor(value * 100))
        easySettings.SaveTable(RealSonar.Path .. "/settings.json", RealSonar.Settings)
    end, RealSonar.Settings.SuitPingVolume)
    textBlock.Text = string.format("Suit Ping Volume %s%%", math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Settings.TinnitusVolume = value
        textBlock.Text = string.format("Tinnitus Volume %s%%", math.floor(value * 100))
        easySettings.SaveTable(RealSonar.Path .. "/settings.json", RealSonar.Settings)
    end, RealSonar.Settings.TinnitusVolume)
    textBlock.Text = string.format("Tinnitus Volume %s%%", math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Settings.DistortionVolume = value
        textBlock.Text = string.format("Distortion Volume %s%%", math.floor(value * 100))
        easySettings.SaveTable(RealSonar.Path .. "/settings.json", RealSonar.Settings)
    end, RealSonar.Settings.DistortionVolume)
    textBlock.Text = string.format("Distortion Volume %s%%", math.floor(slider.BarScrollValue * 100))
end)

dofile(RealSonar.Path .. "/Lua/soundvolume.lua")