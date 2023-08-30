local easySettings = dofile(RealSonar.Path .. "/Lua/easysettings.lua")
local configPath = RealSonar.Path .. "/config.json"

easySettings.AddMenu(TextManager.Get("realsonarsettings").Value, function (parent)
    local list = easySettings.BasicList(parent)
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), TextManager.Get("volumesettings").Value, nil, nil, GUI.Alignment.Center)

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Config.AirPingVolume = math.floor(value * 100)/100
        textBlock.Text = string.format("%s %s%%", TextManager.Get("airpingvolume").Value, math.floor(value * 100))
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.AirPingVolume)
    textBlock.Text = string.format("%s %s%%", TextManager.Get("airpingvolume").Value, math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Config.WaterPingVolume = math.floor(value * 100)/100
        textBlock.Text = string.format("%s %s%%", TextManager.Get("waterpingvolume").Value, math.floor(value * 100))
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.WaterPingVolume)
    textBlock.Text = string.format("%s %s%%", TextManager.Get("waterpingvolume").Value, math.floor(slider.BarScrollValue * 100))

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0, 2, function (value)
        RealSonar.Config.SuitPingVolume = math.floor(value * 100)/100
        textBlock.Text = string.format("%s %s%%", TextManager.Get("suitpingvolume").Value, math.floor(value * 100))
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.SuitPingVolume)
    textBlock.Text = string.format("%s %s%%", TextManager.Get("suitpingvolume").Value, math.floor(slider.BarScrollValue * 100))

    if RealSonar.LITE == false then
        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0, 2, function (value)
            RealSonar.Config.TinnitusVolume = math.floor(value * 100)/100
            textBlock.Text = string.format("%s %s%%", TextManager.Get("tinnitusvolume").Value, math.floor(value * 100))
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.TinnitusVolume)
        textBlock.Text = string.format("%s %s%%", TextManager.Get("tinnitusvolume").Value, math.floor(slider.BarScrollValue * 100))

        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0, 2, function (value)
            RealSonar.Config.DistortionVolume = math.floor(value * 100)/100
            textBlock.Text = string.format("%s %s%%", TextManager.Get("distortionvolume").Value, math.floor(value * 100))
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.DistortionVolume)
        textBlock.Text = string.format("%s %s%%", TextManager.Get("distortionvolume").Value, math.floor(slider.BarScrollValue * 100))
    end

    if Game.IsMultiplayer then
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), TextManager.Get("networksettings").Value, nil, nil, GUI.Alignment.Center)
        local tick = easySettings.TickBox(list.Content, TextManager.Get("lowlatencymode"), function (state)
            RealSonar.Config.LowLatencyMode = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.LowLatencyMode)
        tick.ToolTip = TextManager.Get("lowlatencymodetooltip")
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), TextManager.Get("gameplaysettingsserver").Value, nil, nil, GUI.Alignment.Center)
    else
        GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), list.Content.RectTransform), TextManager.Get("gameplaysettingsclient").Value, nil, nil, GUI.Alignment.Center)
    end

    if RealSonar.LITE == false then
        local tick = easySettings.TickBox(list.Content, TextManager.Get("submarinesonar"), function (state)
            RealSonar.Config.SubmarineSonar = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.SubmarineSonar)
        tick.ToolTip = TextManager.Get("submarinesonartooltip")

        local tick = easySettings.TickBox(list.Content, TextManager.Get("beaconsonar"), function (state)
            RealSonar.Config.BeaconSonar = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.BeaconSonar)
        tick.ToolTip = TextManager.Get("beaconsonartooltip")

        local tick = easySettings.TickBox(list.Content, TextManager.Get("shuttlesonar"), function (state)
            RealSonar.Config.ShuttleSonar = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.ShuttleSonar)
        tick.ToolTip = TextManager.Get("shuttlesonartooltip")

        local tick = easySettings.TickBox(list.Content, TextManager.Get("targetcreatures"), function (state)
            RealSonar.Config.CreatureDamage = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.CreatureDamage)
        tick.ToolTip = TextManager.Get("targetcreaturestooltip")

        local tick = easySettings.TickBox(list.Content, TextManager.Get("targetbots"), function (state)
            RealSonar.Config.BotDamage = state
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.BotDamage)
        tick.ToolTip = TextManager.Get("targetbotstooltip")
    end

    local tick = easySettings.TickBox(list.Content, TextManager.Get("targetplayers"), function (state)
        RealSonar.Config.PlayerDamage = state
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.PlayerDamage)
    tick.ToolTip = TextManager.Get("targetplayerstooltip")

    local tick = easySettings.TickBox(list.Content, TextManager.Get("humanhulldetection"), function (state)
        RealSonar.Config.HumanHullDetection = state
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.HumanHullDetection)
    tick.ToolTip = TextManager.Get("humanhulldetectiontooltip")

    local tick = easySettings.TickBox(list.Content, TextManager.Get("creaturehulldetection"), function (state)
        RealSonar.Config.CreatureHullDetection = state
        easySettings.SaveTable(configPath, RealSonar.Config)
    end, RealSonar.Config.CreatureHullDetection)
    tick.ToolTip = TextManager.Get("creaturehulldetectiontooltip")

    local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
    local slider = easySettings.Slider(list.Content, 0.1, 1.91, function (value)
        RealSonar.Config.SonarRange = math.floor(value * 100)/100
        textBlock.Text = string.format("%s %s%%", TextManager.Get("sonarrange").Value, math.floor(value * 100))
        easySettings.SaveTable(configPath, RealSonar.Config)
        if not Game.IsMultiplayer then
            RealSonar.setSonarRange()
        end
    end, RealSonar.Config.SonarRange)
    textBlock.Text = string.format("%s %s%%", TextManager.Get("sonarrange").Value, math.floor(slider.BarScrollValue * 100))

    if RealSonar.LITE == false then
        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0, 2, function (value)
            RealSonar.Config.SonarDamage = math.floor(value * 100)/100
            textBlock.Text = string.format("%s %s%%", TextManager.Get("sonardamage").Value, math.floor(value * 100))
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.SonarDamage)
        textBlock.Text = string.format("%s %s%%", TextManager.Get("sonardamage").Value, math.floor(slider.BarScrollValue * 100))

        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0.5, 1.5, function (value)
            RealSonar.Config.SonarSlow = math.floor(value * 100)/100
            textBlock.Text = string.format("%s %s%%", TextManager.Get("sonarslow").Value, math.floor(value * 100))
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.SonarSlow)
        textBlock.Text = string.format("%s %s%%", TextManager.Get("sonarslow").Value, math.floor(slider.BarScrollValue * 100))
        
        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0, 2, function (value)
            RealSonar.Config.ImpactVisuals = math.floor(value * 100)/100
            textBlock.Text = string.format("%s %s%%", TextManager.Get("impactvisuals").Value, math.floor(value * 100))
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.ImpactVisuals)
        textBlock.Text = string.format("%s %s%%", TextManager.Get("impactvisuals").Value, math.floor(slider.BarScrollValue * 100))
        
        local title
        if RealSonar.Config.VFXPreset == 2 then
            title = "defaultfx"
        elseif RealSonar.Config.VFXPreset == 1 then
            title = "lowfx"
        elseif RealSonar.Config.VFXPreset >= 0 then
            title = "nofx"
        end
        local textBlock = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), list.Content.RectTransform), "", nil, nil, GUI.Alignment.Center)
        local slider = easySettings.Slider(list.Content, 0, 2, function (value)
            RealSonar.Config.VFXPreset = math.floor(value + 0.5)
            if RealSonar.Config.VFXPreset == 2 then
                title = "defaultfx"
            elseif RealSonar.Config.VFXPreset == 1 then
                title = "lowfx"
            elseif RealSonar.Config.VFXPreset >= 0 then
                title = "nofx"
            end
            textBlock.Text = string.format("%s", TextManager.Get(title).Value)
            easySettings.SaveTable(configPath, RealSonar.Config)
        end, RealSonar.Config.VFXPreset)
        textBlock.Text = string.format("%s", TextManager.Get(title).Value)
    end
end)