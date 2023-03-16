
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "afflictionsCopy")

Hook.Patch(
    "Barotrauma.CharacterHealth",
    "Update",
    function(instance, ptable)
    if instance.Character.AnimController.currentHull and instance.Character.InWater then
        local pathToBreach = false
        local hulls = instance.Character.AnimController.currentHull.GetConnectedHulls(true, 100, true)
        local hullCount = 0
        local waterFilledHulls = 0
        for hull in hulls do
            hullCount = hullCount + 1
            if hull.WaterPercentage >= 50 then
                waterFilledHulls = waterFilledHulls + 1
            end
            for gap in hull.ConnectedGaps do
                if gap.IsRoomToRoom == false and gap.open >= 0.4 and
                -- If water level is above the lower boundary of the gap .
                hull.Surface + hull.WaveY[#hull.WaveY - 1] > gap.rect.Y - gap.Size then
                    -- If character position is below the gap.
                    if instance.Character.Position.Y < gap.rect.Y - gap.Size then
                        if waterFilledHulls >= hullCount - 1 then
                            pathToBreach = true
                        end
                    else
                        pathToBreach = true
                    end
                end
            end
        end

        if pathToBreach == false and instance.Character.InWater == true then
            for affliction in instance.afflictionsCopy do
                -- Stop damage.
                if affliction.Identifier == "activesonar" or
                affliction.Identifier == "sonarimpact" or
                affliction.Identifier == "activesonarbeacon" or
                affliction.Identifier == "sonarimpactbeacon" or
                affliction.Identifier == "sonaroverlay" then
                    affliction.Strength = 0
                end
                -- Stop sounds and play new ones.
                if affliction.Identifier == "sonarsounds" then
                    if affliction.Strength > 95 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirClose", 1)
                    elseif affliction.Strength > 25 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirMedium", 1)
                    elseif affliction.Strength > 0 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirFar", 1)
                    end
                    affliction.Strength = 0
                    
                elseif affliction.Identifier == "sonarsoundsdirectional" then
                    if affliction.Strength > 95 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirCloseDirectional", 1)
                    elseif affliction.Strength > 25 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirMediumDirectional", 1)
                    elseif affliction.Strength > 0 then
                        RealSonar.GiveAffliction(instance.Character, "sonarPingAirFarDirectional", 1)
                    end
                    affliction.Strength = 0
                end

            end
        end
    end

end, Hook.HookMethodType.Before)