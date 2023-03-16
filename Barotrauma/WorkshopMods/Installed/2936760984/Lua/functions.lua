function RealSonar.GiveAffliction(character, identifier, strength)
    local prefab = AfflictionPrefab.Prefabs[identifier]
    local affliction = prefab.Instantiate(strength)
    character.CharacterHealth.ApplyAffliction(character.AnimController.GetLimb(LimbType.Torso), affliction, false)
end