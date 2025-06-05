[in:]
[Guides](/wiki/Category:Guides "Category:Guides"), [Server Administration](/wiki/Category:Server_Administration "Category:Server Administration")

# [Server Settings]

- [Edit source](/wiki/Server_Settings?action=edit)
- [History](/wiki/Server_Settings?action=history)
- [Purge](/wiki/Server_Settings?action=purge)
- [Talk (0)](/wiki/Talk:Server_Settings?action=edit&redlink=1)

[V Rising](/wiki/V_Rising "V Rising") provides a large number of customizable **server settings**. Please read
the [Official Documentation](https://static.wikia.nocookie.net/vrising/images/8/82/VRising_Server_Game_Settings_1.1.1.pdf/revision/latest?cb=20250428141143&format=original)
for the full list of settings. These settings are stored in:

    %UserProfile%\AppData\LocalLow\Stunlock Studios\VRising\Saves\<YOURSAVE>\ServerSettings.json

## Contents

- [[1]{.tocnumber} [Settings]{.toctext}](#Settings)
    - [[1.1]{.tocnumber} [GameDifficulty]{.toctext}](#GameDifficulty)
    - [[1.2]{.tocnumber} [GameModeType]{.toctext}](#GameModeType)
    - [[1.3]{.tocnumber} [CastleDamageMode]{.toctext}](#CastleDamageMode)
    - [[1.4]{.tocnumber} [PlayerDamageMode]{.toctext}](#PlayerDamageMode)
    - [[1.5]{.tocnumber}
      [SiegeWeaponHealth]{.toctext}](#SiegeWeaponHealth)
    - [[1.6]{.tocnumber}
      [CastleHeartDamageMode]{.toctext}](#CastleHeartDamageMode)
    - [[1.7]{.tocnumber}
      [PvPProtectionMode]{.toctext}](#PvPProtectionMode)
    - [[1.8]{.tocnumber}
      [DeathContainerPermission]{.toctext}](#DeathContainerPermission)
    - [[1.9]{.tocnumber} [RelicSpawnType]{.toctext}](#RelicSpawnType)
    - [[1.10]{.tocnumber}
      [CanLootEnemyContainers]{.toctext}](#CanLootEnemyContainers)
    - [[1.11]{.tocnumber}
      [BloodBoundEquipment]{.toctext}](#BloodBoundEquipment)
    - [[1.12]{.tocnumber}
      [TeleportBoundItems]{.toctext}](#TeleportBoundItems)
    - [[1.13]{.tocnumber} [BatBoundItems]{.toctext}](#BatBoundItems)
    - [[1.14]{.tocnumber} [BatBoundShards]{.toctext}](#BatBoundShards)
    - [[1.15]{.tocnumber} [AllowGlobalChat]{.toctext}](#AllowGlobalChat)
    - [[1.16]{.tocnumber}
      [AllWaypointsUnlocked]{.toctext}](#AllWaypointsUnlocked)
    - [[1.17]{.tocnumber} [FreeCastleRaid]{.toctext}](#FreeCastleRaid)
    - [[1.18]{.tocnumber} [FreeCastleClaim]{.toctext}](#FreeCastleClaim)
    - [[1.19]{.tocnumber}
      [FreeCastleDestroy]{.toctext}](#FreeCastleDestroy)
    - [[1.20]{.tocnumber}
      [CastleRelocationEnabled]{.toctext}](#CastleRelocationEnabled)
    - [[1.21]{.tocnumber} [Inactivity
      Settings]{.toctext}](#Inactivity_Settings)
    - [[1.22]{.tocnumber} [Disconnected Player
      Settings]{.toctext}](#Disconnected_Player_Settings)
    - [[1.23]{.tocnumber}
      [InventoryStacksModifier]{.toctext}](#InventoryStacksModifier)
    - [[1.24]{.tocnumber} [Drop Rate
      Modifiers]{.toctext}](#Drop_Rate_Modifiers)
    - [[1.25]{.tocnumber}
      [SoulShard_DurabilityLossRate]{.toctext}](#SoulShard_DurabilityLossRate)
    - [[1.26]{.tocnumber}
      [MaterialYieldModifier_Global]{.toctext}](#MaterialYieldModifier_Global)
    - [[1.27]{.tocnumber}
      [BloodEssenceYieldModifier]{.toctext}](#BloodEssenceYieldModifier)
    - [[1.28]{.tocnumber}
      [JournalVBloodSourceUnitMaxDistance]{.toctext}](#JournalVBloodSourceUnitMaxDistance)
    - [[1.29]{.tocnumber}
      [PvPVampireRespawnModifier]{.toctext}](#PvPVampireRespawnModifier)
    - [[1.30]{.tocnumber}
      [CastleMinimumDistanceInFloors]{.toctext}](#CastleMinimumDistanceInFloors)
    - [[1.31]{.tocnumber} [ClanSize]{.toctext}](#ClanSize)
    - [[1.32]{.tocnumber}
      [BloodDrainModifier]{.toctext}](#BloodDrainModifier)
    - [[1.33]{.tocnumber}
      [DurabilityDrainModifier]{.toctext}](#DurabilityDrainModifier)
    - [[1.34]{.tocnumber} [Environmental Hazard
      Modifiers]{.toctext}](#Environmental_Hazard_Modifiers)
    - [[1.35]{.tocnumber}
      [CastleDecayRateModifier]{.toctext}](#CastleDecayRateModifier)
    - [[1.36]{.tocnumber}
      [CastleBloodEssenceDrainModifier]{.toctext}](#CastleBloodEssenceDrainModifier)
    - [[1.37]{.tocnumber} [Castle State
      Timers]{.toctext}](#Castle_State_Timers)
    - [[1.38]{.tocnumber}
      [AnnounceSiegeWeaponSpawn]{.toctext}](#AnnounceSiegeWeaponSpawn)
    - [[1.39]{.tocnumber}
      [ShowSiegeWeaponMapIcon]{.toctext}](#ShowSiegeWeaponMapIcon)
    - [[1.40]{.tocnumber}
      [BuildCostModifier]{.toctext}](#BuildCostModifier)
    - [[1.41]{.tocnumber}
      [RecipeCostModifier]{.toctext}](#RecipeCostModifier)
    - [[1.42]{.tocnumber}
      [CraftRateModifier]{.toctext}](#CraftRateModifier)
    - [[1.43]{.tocnumber}
      [ResearchCostModifier]{.toctext}](#ResearchCostModifier)
    - [[1.44]{.tocnumber}
      [ResearchTimeModifier]{.toctext}](#ResearchTimeModifier)
    - [[1.45]{.tocnumber}
      [RefinementCostModifier]{.toctext}](#RefinementCostModifier)
    - [[1.46]{.tocnumber}
      [RefinementRateModifier]{.toctext}](#RefinementRateModifier)
    - [[1.47]{.tocnumber}
      [DismantleResourceModifier]{.toctext}](#DismantleResourceModifier)
    - [[1.48]{.tocnumber}
      [ServantConvertRateModifier]{.toctext}](#ServantConvertRateModifier)
    - [[1.49]{.tocnumber}
      [RepairCostModifier]{.toctext}](#RepairCostModifier)
    - [[1.50]{.tocnumber} [Death Durability Loss
      Settings]{.toctext}](#Death_Durability_Loss_Settings)
    - [[1.51]{.tocnumber}
      [StarterEquipmentId]{.toctext}](#StarterEquipmentId)
    - [[1.52]{.tocnumber}
      [StarterResourceId]{.toctext}](#StarterResourceId)
    - [[1.53]{.tocnumber}
      [StartingProgressionLevel]{.toctext}](#StartingProgressionLevel)
    - [[1.54]{.tocnumber} [UnlockedAchievements
      (Quests)]{.toctext}](#UnlockedAchievements_(Quests))
    - [[1.55]{.tocnumber}
      [UnlockedResearchs]{.toctext}](#UnlockedResearchs)
    - [[1.56]{.tocnumber}
      [VBloodUnitSettings]{.toctext}](#VBloodUnitSettings)
        - [[1.56.1]{.tocnumber} [VBloodUnitSetting
          Structure]{.toctext}](#VBloodUnitSetting_Structure)
    - [[1.57]{.tocnumber}
      [GameTimeModifiers]{.toctext}](#GameTimeModifiers)
        - [[1.57.1]{.tocnumber} [GameTimeModifier
          Settings]{.toctext}](#GameTimeModifier_Settings)
    - [[1.58]{.tocnumber}
      [VampireStatModifiers]{.toctext}](#VampireStatModifiers)
        - [[1.58.1]{.tocnumber} [VampireStatModifier
          Settings]{.toctext}](#VampireStatModifier_Settings)
    - [[1.59]{.tocnumber} [UnitStatModifiers_Global
      Settings]{.toctext}](#UnitStatModifiers_Global_Settings)
    - [[1.60]{.tocnumber}
      [UnitStatModifiers_VBlood]{.toctext}](#UnitStatModifiers_VBlood)
    - [[1.61]{.tocnumber}
      [EquipmentStatModifiers_Global]{.toctext}](#EquipmentStatModifiers_Global)
        - [[1.61.1]{.tocnumber} [EquipmentStatModifier
          Settings]{.toctext}](#EquipmentStatModifier_Settings)
    - [[1.62]{.tocnumber}
      [CastleStatModifiers_Global]{.toctext}](#CastleStatModifiers_Global)
        - [[1.62.1]{.tocnumber} [CastleStatModifier
          Settings]{.toctext}](#CastleStatModifier_Settings)
        - [[1.62.2]{.tocnumber} [HeartLimits
          Structure]{.toctext}](#HeartLimits_Structure)
        - [[1.62.3]{.tocnumber} [HeartLevelLimit
          Structure]{.toctext}](#HeartLevelLimit_Structure)
    - [[1.63]{.tocnumber}
      [PlayerInteractionSettings]{.toctext}](#PlayerInteractionSettings)
        - [[1.63.1]{.tocnumber} [PlayerInteraction
          Settings]{.toctext}](#PlayerInteraction_Settings)
        - [[1.63.2]{.tocnumber} [StartEndTimeData
          Structure]{.toctext}](#StartEndTimeData_Structure)
    - [[1.64]{.tocnumber} [TraderModifiers]{.toctext}](#TraderModifiers)
        - [[1.64.1]{.tocnumber} [TraderModifier
          Settings]{.toctext}](#TraderModifier_Settings)
    - [[1.65]{.tocnumber}
      [WarEventGameSettings]{.toctext}](#WarEventGameSettings)
        - [[1.65.1]{.tocnumber} [WarEventGame
          Settings]{.toctext}](#WarEventGame_Settings)

## [Settings]

This page details the server settings available for configuration, based
on the structure found in the \`ServerHostSettings.json\` file.

### [GameDifficulty]

Defines the behaviour and complexity of V Blood Bosses.

- **0**: Relaxed - Bosses generally use simpler mechanics.
- **1**: Normal - Bosses use their standard mechanics and behaviours.
- **2**: Hard (Brutal) - Bosses employ more advanced mechanics and
  tougher behaviours.

Advertisement

### [GameModeType]

Defines the core ruleset for player interaction.

- **0**: PvE (Player vs Environment) - Players cannot directly harm each
  other or their castles.
- **1**: PvP (Player vs Player) - Players can engage in combat and
  potentially raid castles, subject to other settings.

### [CastleDamageMode]

Defines if and when players can damage other players\' castles. Only
active if **GameModeType** is PvP.

- **0**: Never - Player castles cannot be damaged by other players.
- **1**: Always - Player castles can always be damaged by other players.
- **2**: TimeRestricted - Player castles can only be damaged during
  specific time windows defined in
  [#PlayerInteractionSettings](#PlayerInteractionSettings).

### [PlayerDamageMode]

Defines if and when players can damage other players. Only active if
**GameModeType** is PvP.

- **0**: Always - Players can always damage each other.
- **1**: TimeRestricted - Players can only damage each other during
  specific time windows defined in
  [#PlayerInteractionSettings](#PlayerInteractionSettings).

### [SiegeWeaponHealth]

Defines the health points of Siege Golems.

- **0**: VeryLow (750 HP)
- **1**: Low (1000 HP)
- **2**: Normal (1250 HP)
- **3**: High (1750 HP)
- **4**: VeryHigh (2500 HP) - *default in 1.1*
- **5**: MegaHigh (3250 HP)
- **6**: UltraHigh (4000 HP)
- **7**: CrazyHigh (5000 HP)
- **8**: Max (7500 HP)

Advertisement

### [CastleHeartDamageMode]

Defines if and how players can destroy or seize other players\' Castle
Hearts. Affected by **CastleDamageMode** and only relevant in PvP.

- **0**: CanBeDestroyedOnlyWhenDecaying - Castle Heart can only be
  destroyed by players while the castle is decaying (out of Blood
  Essence).
- **1**: CanBeDestroyedByPlayers - Castle Heart can be destroyed by
  players (subject to CastleDamageMode rules).
- **2**: CanBeSeizedOrDestroyedByPlayers - Castle Heart can be seized
  (claimed) or destroyed by players (subject to CastleDamageMode rules).

### [PvPProtectionMode]

If PvP is enabled, defines how long a player is protected from PvP
damage after spawning or respawning.

- **0**: Disabled (0 seconds)
- **1**: VeryShort (900 seconds / 15 Minutes)
- **2**: Short (1800 seconds / 30 Minutes)
- **3**: Medium (3600 seconds / 1 Hour)
- **4**: Long (7200 seconds / 2 Hours)

### [DeathContainerPermission]

Sets permission for who can loot a player\'s dropped inventory (Death
Container) upon their death.

- **0**: Anyone - Anyone can loot the death container.
- **1**: ClanMembers - Only members of the deceased\'s clan can loot.
- **2**: OnlySelf - Only the owner of the death container can loot.

### [RelicSpawnType]

Defines how many Relics (Soul Shards) can exist in the world.

- **0**: Unique - Only one of each Shard type can exist at any time.
  They are destroyed if their holder dies and they are not recovered.
- **1**: Plentiful - There is no limit to how many of each Shard type
  can exist simultaneously.

Advertisement

### [CanLootEnemyContainers]

Defines if players can loot storage containers (e.g., chests,
workbenches) within enemy castles that they do not own.

- **false** (0): Cannot loot enemy containers.
- **true** (1): Can loot enemy containers.

### [BloodBoundEquipment]

If enabled, players will keep their equipped armor and weapons upon
death. Durability loss still applies based on other settings.

- **false** (0): Equipment is dropped in the Death Container on death.
- **true** (1): Equipped items remain on the player after death.

### [TeleportBoundItems]

When enabled (true), carrying certain items prevents the player from
using Vampire [Waygates](/wiki/Waygates "Waygates") or transforming into
[Bat Form](/wiki/Bat_Form "Bat Form") for travel.

- **false** (0): Players can teleport while carrying resource items.
- **true** (1): Carrying resource items blocks teleportation.

### [BatBoundItems]

When enabled (true), carrying certain items prevents the player from
transforming into [Bat Form](/wiki/Bat_Form "Bat Form") for travel.

- **false** (0): Players can use Bat Form while carrying resource items.
- **true** (1): Carrying resource items blocks Bat Form usage.

### [BatBoundShards]

When enabled (true), players can now carry [Soul
Shards](/wiki/Category:Soul_Shards "Category:Soul Shards") while
transforming into [Bat Form](/wiki/Bat_Form "Bat Form") for travel.

- **false** (0): Carrying Soul Shards blocks Bat Form usage.
- **true** (1): Players can use Bat Form while carrying Soul Shards.

Advertisement

### [AllowGlobalChat]

Enables or disables the server-wide global chat channel. Local chat is
always available.

- **false** (0): Global chat disabled.
- **true** (1): Global chat enabled.

### [AllWaypointsUnlocked]

If enabled, all Vampire [Waygates](/wiki/Waygates "Waygates") across the
map will be unlocked for all players by default, without needing
discovery.

- **false** (0): Players must discover Waygates to use them.
- **true** (1): All Waygates are unlocked from the start.

### [FreeCastleRaid]

Defines if breaching castle defenses during permitted raid times
requires materials (e.g., explosives) or is free.

- **false** (0): Raiding requires siege materials.
- **true** (1): Raiding does not require specific siege materials (basic
  attacks may suffice, needs verification).

### [FreeCastleClaim]

Defines if claiming an empty Castle Territory plot or a destroyed enemy
Castle Heart requires Castle Heart materials or is free.

- **false** (0): Claiming requires materials.
- **true** (1): Claiming is free.

### [FreeCastleDestroy]

Defines if destroying an enemy Castle Heart (when permitted by other
settings) requires specific actions/materials or is free.

- **false** (0): Destroying may have requirements (e.g., specific
  interaction).
- **true** (1): Destroying is straightforward once defenses are down.

Advertisement

### [CastleRelocationEnabled]

Defines if players are allowed to use the Castle Relocation feature to
move their entire castle base.

- **false** (0): Castle Relocation is disabled.
- **true** (1): Castle Relocation is enabled.

### [Inactivity Settings]

These settings control the automatic killing of players deemed inactive.
This is often used to free up server slots or prevent bases from being
permanently occupied by absent players.

- **InactivityKillEnabled**: Enables (true) or disables (false) the
  entire inactivity kill feature.

<!-- -->

* false (0)
* true (1)

- **InactivityKillTimeMin**: Minimum duration (in seconds) a player must
  be continuously logged out/inactive before being eligible for killing.
  This time applies to players at or below Item Level 1. (Value: number,
  e.g., 3600)
- **InactivityKillTimeMax**: Maximum duration (in seconds) a player must
  be continuously logged out/inactive before being eligible for killing.
  This time applies to players at or above
  **InactivityKillTimerMaxItemLevel**. (Value: number, e.g., 86400)
- **InactivityKillTimerMaxItemLevel**: The player Item Level at which
  the maximum inactivity time (**InactivityKillTimeMax**) is applied.
  The time scales linearly between Min and Max based on item level below
  this threshold. (Range: **0** - **255**)
- **InactivityKillSafeTimeAddition**: Additional time (in seconds) added
  to the inactivity timer if the player logs out while inside their own
  powered castle territory (considered a safe spot). (Value: number,
  e.g., 1800)

### [Disconnected Player Settings]

Settings affecting player characters whose users disconnect from the
server.

- **DisableDisconnectedDeadEnabled**: If enabled (true), the vampire
  character of a disconnected player remains in the world vulnerable
  until the player reconnects. If false, the character becomes
  invulnerable/disabled after a timer.

<!-- -->

* false (0)
* true (1)

- **DisableDisconnectedDeadTimer**: If
  **DisableDisconnectedDeadEnabled** is false, this is the duration (in
  seconds) after disconnection before the player\'s character becomes
  disabled/invulnerable. (Value: number, e.g., 600)
- **DisconnectedSunImmunityTime**: Duration (in seconds) a player\'s
  character is immune to sun damage immediately after disconnecting
  while standing in direct sunlight. (Range: **0** - **3600**)

Advertisement

### [InventoryStacksModifier]

Multiplier applied to the maximum stack size for all stackable items in
player inventories and storage containers. Default is 1.0.

- **Range**: 0.25 to 3.0

### [Drop Rate Modifiers]

Multipliers affecting the quantity of items dropped. Default is 1.0.

- **DropTableModifier_General**: Multiplier for general loot drops from
  enemies, breakables, and chests in the world. (Range: **0.25** to
  **3.0**)
- **DropTableModifier_Missions**: Multiplier for loot rewards obtained
  from successful Servant Hunt missions. (Range: **0.25** to **3.0**)
- **DropTableModifier_StygianShards**: Multiplier specifically for the
  drop rate of Stygian Shards during Rift Incursion events. (Range:
  **0.25** to **3.0**)

### [SoulShard_DurabilityLossRate]

Multiplier for the rate at which held Soul Shards lose durability over
time. Default is 1.0. Set to 0 to disable durability loss.

- **Range**: 0.0 to 3.0

### [MaterialYieldModifier_Global]

Multiplier for the amount of resources (e.g., wood, stone, ore) gained
per swing when harvesting resource nodes. Default is 1.0.

- **Range**: 0.25 to 3.0

### [BloodEssenceYieldModifier]

Multiplier for the amount of Blood Essence obtained from defeating
living creatures (humans, creatures). Default is 1.0.

- **Range**: 0.25 to 3.0

Advertisement

### [JournalVBloodSourceUnitMaxDistance]

*This setting is currently unused.*

### [PvPVampireRespawnModifier]

Multiplier applied to the base respawn timer for players after being
killed in PvP combat. Default is 1.0. Lower values result in faster
respawns.

- **Range**: 0.0 to 3.0

### [CastleMinimumDistanceInFloors]

*This setting is unused/broken since the introduction of Castle
Territories.*

### [ClanSize]

Defines the maximum number of players allowed in a single clan.

- **Range**: 1 to 50

### [BloodDrainModifier]

Multiplier for the passive rate at which a vampire\'s blood pool drains
over time. Default is 1.0. Higher values mean blood drains faster. Set
to 0 to disable passive blood drain.

- **Range**: 0.0 to 3.0

### [DurabilityDrainModifier]

Multiplier for the rate at which equipped items (armor, weapons) lose
durability from use (attacking, taking damage). Default is 1.0. Higher
values mean durability is lost faster. Set to 0 to disable durability
loss.

- **Range**: 0.0 to 3.0

Advertisement

### [Environmental Hazard Modifiers]

Multipliers affecting the strength or damage of various environmental
hazards for vampires. Default is 1.0. Higher values increase the
negative effect.

- **GarlicAreaStrengthModifier**: Multiplier for the intensity of the
  negative effects (damage, increased damage taken) when exposed to
  Garlic. (Range: **0.0** to **3.0**)
- **HolyAreaStrengthModifier**: Multiplier for the intensity of damage
  taken when exposed to Holy Radiation areas. (Range: **0.0** to
  **3.0**)
- **SilverStrengthModifier**: Multiplier for the intensity of damage
  taken from carrying Silver items (coins, ore). (Range: **0.0** to
  **3.0**)
- **SunDamageModifier**: Multiplier for damage taken when exposed to
  direct Sunlight. (Range: **0.0** to **3.0**)

### [CastleDecayRateModifier]

Multiplier for how quickly a Castle Heart loses health and its
structures decay when it has run out of Blood Essence. Default is 1.0.
Higher values mean faster decay.

- **Range**: 0.0 to 3.0

### [CastleBloodEssenceDrainModifier]

Multiplier for the rate at which a powered Castle Heart consumes Blood
Essence to maintain its structures and prevent decay. Default is 1.0.
Higher values mean faster consumption.

- **Range**: 0.0 to 3.0

### [Castle State Timers]

Timers related to castle states, primarily relevant during PvP raid
windows. Durations are in seconds.

- **CastleSiegeTimer**: Duration a castle remains in the \"Breached\" or
  vulnerable state after its defenses are initially destroyed during a
  raid, allowing the Castle Heart to be damaged/seized. (Range: **60**
  to **1800**)
- **CastleUnderAttackTimer**: Duration a castle is flagged as \"Under
  Attack\" after taking damage from an enemy player. (Range: **0** to
  **60**)
- **CastleRaidTimer**: Duration that castle defenses (doors, walls
  potentially) remain disabled or easily destroyable after the Castle
  Heart is damaged during a PvP raid window. (Range: **60** to **3600**)
- **CastleRaidProtectionTime**: Duration (in seconds) a castle is
  protected from subsequent raids after being successfully raided (e.g.,
  Heart damaged or seized). (Range: **0** to **604800** (7 Days))
- **CastleExposedFreeClaimTimer**: Duration (in seconds) after a castle
  plot becomes abandoned (due to decay or owner deletion) that it
  remains claimable for free before requiring the standard material cost
  to claim. (Range: **0** to **3600**)
- **CastleRelocationCooldown**: Cooldown period (in seconds) after using
  the Castle Relocation feature before it can be used again. (Range:
  **0** to **2592000** (30 Days))

Advertisement

### [AnnounceSiegeWeaponSpawn]

If enabled (true), a server-wide message announces when a player crafts
a Siege Golem.

- **false** (0)
- **true** (1)

### [ShowSiegeWeaponMapIcon]

If enabled (true), active Siege Golems will appear as icons on the map
for all players.

- **false** (0)
- **true** (1)

### [BuildCostModifier]

Multiplier for the material cost required to place structures, walls,
floors, and other building elements in a castle. Default is 1.0.

- **Range**: 0.0 to 3.0

### [RecipeCostModifier]

Multiplier for the material cost required to craft items at various
workstations (e.g., Furnace, Grinder, Tailoring Bench). Default is 1.0.

- **Range**: 0.0 to 3.0

### [CraftRateModifier]

Multiplier for the speed at which items are crafted at workstations.
Default is 1.0. Higher values mean faster crafting.

- **Range**: 0.25 to 6.0

Advertisement

### [ResearchCostModifier]

Multiplier for the cost (e.g., Paper, Scrolls, Schematics) required to
unlock research and technologies at the Research Desk, Study, or
Athenaeum. Default is 1.0.

- **Range**: 0.0 to 3.0

### [ResearchTimeModifier]

*This setting is currently unused.* (Research completion is typically
instant upon spending cost).

### [RefinementCostModifier]

Multiplier for the input material cost required for refining resources
(e.g., ore into ingots at Furnace, logs into planks at Sawmill). Default
is 1.0.

- **Range**: 0.0 to 3.0

### [RefinementRateModifier]

Multiplier for the speed at which resources are refined at workstations.
Default is 1.0. Higher values mean faster refinement.

- **Range**: 0.25 to 6.0

### [DismantleResourceModifier]

Multiplier determining the percentage of the original material cost
returned to the player when dismantling a placed structure or object.
Default is 1.0 (100%).

- **Range**: 0.0 to 1.0

### [ServantConvertRateModifier]

Multiplier for the speed at which captured humans are converted into
Servants inside Servant Coffins. Default is 1.0. Higher values mean
faster conversion.

- **Range**: 0.25 to 6.0

Advertisement

### [RepairCostModifier]

Multiplier for the material cost required to repair damaged equipment at
a workbench or via the inventory UI. Default is 1.0.

- **Range**: 0.0 to 3.0

### [Death Durability Loss Settings]

Settings controlling how much durability is lost from equipment upon
player death.

- **Death_DurabilityFactorLoss**: The percentage of maximum durability
  lost from equipped items when a player dies (only applies if
  **BloodBoundEquipment** is false). Default is 0.125 (12.5%). Setting
  to 0 disables durability loss on death.

<!-- -->

* Range: 0.0 to 1.0

- **Death_DurabilityLossFactorAsResource**: The percentage of the
  durability value lost on death that is dropped as corresponding repair
  materials in the Death Container, instead of just being lost
  durability. Default is 1.0 (100%). If set to 0, no repair resources
  are dropped, only durability is lost.

<!-- -->

* Range: 0.0 to 1.0

### [StarterEquipmentId]

Defines the set of equipment players start with when first spawning in
the crypt. Uses internal identifiers for equipment sets.

---------------------- ------------- -----------------------------------------------------------------------------------------------------------
Setting Name json ID Equipment Provided (Details may need verification)
**None**               0 Standard start, nothing extra.
**Copper**             742198603 Basic Copper weapons.
**Merciless Copper**   -663535879 Merciless Copper weapons.
**Iron**               688096336 Full set of Iron weapons, Hollowfang armor set, Hunter\'s Cloak, Scourgestone Pendant,
Silver Thread Bag.
**Merciless Iron**     -1502721803 Merciless Iron weapons & likely corresponding gear.
**Dark Silver**        28431735 Dark Silver weapons & likely corresponding gear.
**Sanguine**           -983090495 Sanguine weapons & likely corresponding gear.
**Dracula**            -1466803079 Ancestral weapons & gear (End-game).
---------------------- ------------- -----------------------------------------------------------------------------------------------------------

: Starting equipment per setting\
[Collapse]

Advertisement

### [StarterResourceId]

Determines a bundle of starting resources the player spawns with, often
corresponding to a certain progression level. Uses internal identifiers.

----------------------- ------------- ---------------------------------------------------------------------------------------------
Setting Name json ID Resources Provided (Examples, exact contents need verification)
**None**                0 Nothing extra.
**Level 30 Supplies**   1982471388 Resources appropriate for Level 30 progression (e.g., Iron Ingots, Leather,
Scourgestones).
**Level 40 Supplies**   1504234317 Resources appropriate for Level 40 progression.
**Level 50 Supplies**   548330870 Resources appropriate for Level 50 progression (e.g., Dark Silver Ingots, Spectral
Dust).
**Level 60 Supplies**   815373441 Resources appropriate for Level 60 progression.
**Level 70 Supplies**   -1370930855 Resources appropriate for Level 70 progression (e.g., Gold Ingots, Silk).
**Level 80 Supplies**   -1394108841 Resources appropriate for Level 80 progression (End-game).
----------------------- ------------- ---------------------------------------------------------------------------------------------

: Starting resources per setting\
[Collapse]

### [StartingProgressionLevel]

Defines the starting \"progression level\" for new players. Default is

0. It is unknown what this setting does.

- **Range**: 0 to 255 (Meaningful values likely correspond to certain
  progression milestones).

Advertisement

### [UnlockedAchievements (Quests)]

This setting controls which [Quests](/wiki/Journal "Journal") will
automatically be granted to new players joining the server. The
**UnlockedAchievements** setting will grant all preceding quest rewards
up to the specified quest.

Quest Name ID
------------------------------------------------------------------------------------------------------ -------------
[Collecting the Remains](/wiki/Collecting_the_Remains "Collecting the Remains")                        -1770927128
[Wielding the Sword](/wiki/Wielding_the_Sword "Wielding the Sword")                                    436375429
[Mastering Magic](/wiki/Mastering_Magic "Mastering Magic")                                             -1400391027
[Defensive Measures](/wiki/Defensive_Measures "Defensive Measures")                                    -2102083739
[Hides of the Wild](/wiki/Hides_of_the_Wild "Hides of the Wild")                                       1566228114
[Into the Woods](/wiki/Into_the_Woods "Into the Woods")                                                1695239324
[Gathering](/wiki/Gathering "Gathering")                                                               -54280488
[Lord of Shadows](/wiki/Lord_of_Shadows "Lord of Shadows")                                             1694767961
[Fortify](/wiki/Fortify "Fortify")                                                                     -1899098914
[Shelter](/wiki/Shelter "Shelter")                                                                     -122882616
[Getting Ready for the Hunt](/wiki/Getting_Ready_for_the_Hunt "Getting Ready for the Hunt")            560247139
[Blood Hunt](/wiki/Blood_Hunt "Blood Hunt")                                                            -1995132640
[Thirst for Power](/wiki/Thirst_for_Power "Thirst for Power")                                          -302458684
[The First Book in the Library](/wiki/The_First_Book_in_the_Library "The First Book in the Library")   -1434604634
[Expanding my Domain](/wiki/Expanding_my_Domain "Expanding my Domain")                                 1668809517
[Building a Castle](/wiki/Building_a_Castle "Building a Castle")                                       334973636
[Waygate](/wiki/Waygate "Waygate")                                                                     134993992
[Lord of the Manor](/wiki/Lord_of_the_Manor "Lord of the Manor")                                       606418711
[Servants](/wiki/Servants "Servants")                                                                  -892747762
[Army of Darkness](/wiki/Army_of_Darkness "Army of Darkness")                                          -437605270
[Broaden Horizons](/wiki/Broaden_Horizons "Broaden Horizons")                                          -1472413073
[Blood on Tap](/wiki/Blood_on_Tap "Blood on Tap")                                                      1248242594
[Throne of Command](/wiki/Throne_of_Command "Throne of Command")                                       -327597689
[Reign Supreme](/wiki/Reign_Supreme "Reign Supreme")                                                   149111189
[An Eye into Mortium](/wiki/An_Eye_into_Mortium "An Eye into Mortium")                                 -452204266
[A Castle reaching the Sky](/wiki/A_Castle_reaching_the_Sky "A Castle reaching the Sky")               1805684941
[Nightfall Steed](/wiki/Nightfall_Steed "Nightfall Steed")                                             -699165894
[Vampire Empire](/wiki/Vampire_Empire "Vampire Empire")                                                1861267375
[Soul Stones](/wiki/Soul_Stones "Soul Stones")                                                         -2104585843
[Lord of the Night](/wiki/Lord_of_the_Night "Lord of the Night")                                       1762480233

: Quest IDs

Advertisement

### [UnlockedResearchs]

Sets which tiers of research are unlocked by default for new players
joining the server. Each tier corresponds to completing all research
available at a specific workstation.

- Add the following IDs to the list to unlock respective tiers:
- **-495424062**: Tier 1 (Research Desk technologies)
- **-1292809886**: Tier 2 (Study technologies)
- **-1262194203**: Tier 3 (Athenaeum technologies)
- Example: \`\"UnlockedResearchs\": \[-495424062\]\` unlocks all Tier 1
  research automatically.
- **Note:** This setting likely only affects newly created characters on
  the server after the setting is applied. It may not retroactively
  unlock research for existing characters. Use console commands for
  existing characters if needed.

### [VBloodUnitSettings]

A list containing specific settings overrides for individual V Blood
bosses. Each entry in the list follows the [VBloodUnitSetting
structure](#VBloodUnitSetting_Structure) below. This allows modification
of specific boss levels or making them unlocked by default. To change
all bosses globally, see
**[UnitStatModifiers_VBlood](#UnitStatModifiers_VBlood)**. Example
structure (within the main JSON):

"VBloodUnitSettings": [
,

// ... more entries for other bosses can be added
]

Advertisement

#### [VBloodUnitSetting Structure]

This structure is used for each entry within the main
**[VBloodUnitSettings](#VBloodUnitSettings)** list to apply specific
overrides to V Blood bosses.

- **UnitId** (integer): The unique identifier for the V Blood boss. See
  table below for known IDs.
- **UnitLevel** (byte): Overrides the default level of the V Blood boss.
  Set to **0** to use the boss\'s normal level. (Range: **0** - **255**)
- **DefaultUnlocked** (boolean): If **true**, information about this V
  Blood boss (location, rewards) is available in the V Blood tracking
  menu from the start. If **false**, players must discover or track them
  normally. (**false** / **true**)

UnitId Boss Name
------------- ----------------------------------
-1905691330 Alpha the White Wolf
1124739990 Keely the Frost Archer
-2025101517 Errol the Stonebreaker
2122229952 Rufus the Foreman
1106149033 Grayson the Armourer
577478542 Goreswine the Ravager
763273073 Lidia the Chaos Archer
1896428751 Clive the Firestarter
-2039908510 Nibbles the Putrid Rat
-2122682556 Finn the Fisherman
-484556888 Polora the Feywalker
-1391546313 Kodia the Ferocious Bear
153390636 Nicholaus the Fallen
-1659822956 Quincey the Bandit King
-1942352521 Beatrice the Tailor
-29797003 Vincent the Frostbringer
-99012450 Christina the Sun Priestess
-1449631170 Tristan the Vampire Hunter
619948378 Sir Erwin the Gallant Cavalier
-1365931036 Kriig the Undead General
939467639 Leandra the Shadow Priestess
1945956671 Maja the Dark Savant
613251918 Bane the Shadowblade
910988233 Grethel the Glassblower
850622034 Meredith the Bright Archer
-1065970933 Terah the Geomancer
24378719 Frostmaw the Mountain Terror
795262842 General Elena the Hollow
-753453016 Gaius the Cursed Champion
-496360395 General Cassius the Betrayer
-1968372384 Jade the Vampire Hunter
-680831417 Raziel the Shepherd
1688478381 Octavian the Militia Captain
172235178 Ziva the Engineer
-1101874342 Domina the Blade Dancer
106480588 Angram the Purifier
-548489519 Ungora the Spider Queen
109969450 Ben the Old Wanderer
-1208888966 Foulrot the Soultaker
-203043163 Albert the Duke of Balaton
-1505705712 Willfred the Village Elder
326378955 Cyril the Cursed Smith
-26105228 Sir Magnus the Overseer
192051202 Baron du Bouchon the Sommelier
685266977 Morian the Stormwing Matriarch
-2013903325 Mairwyn the Elementalist
814083983 Henry Blackbrew the Doctor
-1383529374 Jakira the Shadow Huntress
-1669199769 Stavros the Carver
1295855316 Lucile the Venom Alchemist
-910296704 Matka the Curse Weaver
-1347412392 Terrorclaw the Ogre
114912615 Azariel the Sunbringer
2054432370 Voltatia the Power Master
336560131 Simon Belmont the Vampire Hunter
173259239 Dantos the Forgebinder
1112948824 Lord Styx the Night Champion
-1936575244 Gorecrusher the Behemoth
495971434 General Valencia the Depraved
-740796338 Solarus the Immaculate
-393555055 Talzur the Winged Horror
591725925 Megara the Serpent Queen
1233988687 Adam the Firstborn
-327335305 Dracula the Immortal King

: V Blood Unit IDs

Advertisement

### [GameTimeModifiers]

Contains settings related to the game\'s day/night cycle duration and
[Blood Moon](/wiki/Blood_Moon "Blood Moon") frequency.

#### [GameTimeModifier Settings]

Settings controlling the game\'s time flow and Blood Moons.

- **DayDurationInSeconds**: The total length of a full in-game day-night
  cycle in real-world seconds. (Range: **60** to **86400** (24 hours))
- **DayStartHour**: The in-game hour (0-23) when daytime begins (sun
  rises). (Range: **0** to **23**)
- **DayStartMinute**: The in-game minute (0-59) when daytime begins.
  (Range: **0** to **59**)
- **DayEndHour**: The in-game hour (0-23) when nighttime begins (sun
  sets). (Range: **0** to **23**)
- **DayEndMinute**: The in-game minute (0-59) when nighttime begins.
  (Range: **0** to **59**)
- **BloodMoonFrequency_Min**: The minimum number of full in-game days
  that must pass between the end of one Blood Moon and the start of the
  next. (Range: **1** to **255**)
- **BloodMoonFrequency_Max**: The maximum number of full in-game days
  that can pass before a Blood Moon is guaranteed to occur (if one
  hasn\'t happened sooner due to random chance within the Min/Max
  window). (Range: **1** to **255**)
- **BloodMoonBuff**: A multiplier affecting the strength of the stat
  bonuses granted to players (and potentially enemies) during a Blood
  Moon event. Default is 0.2 (20%). (Range: **0.0** to **1.0**, needs
  confirmation if \> 1 is possible)

### [VampireStatModifiers]

Contains settings that apply multiplicative modifiers to base stats for
all player vampires.

#### [VampireStatModifier Settings]

Multiplicative modifiers applied to the base stats of player vampires.
Default is 1.0 (no change).

- **MaxHealthModifier**: Multiplier for base maximum health. (Range:
  **0.01** to **10.0**)
- **PhysicalPowerModifier**: Multiplier for base physical power (affects
  weapon damage). (Range: **0.01** to **10.0**)
- **SpellPowerModifier**: Multiplier for base spell power (affects
  ability damage/effectiveness). (Range: **0.01** to **10.0**)
- **ResourcePowerModifier**: Multiplier for the damage dealt per swing
  to resource nodes (trees, rocks, veins). Affects harvesting speed.
  (Range: **0.01** to **10.0**)
- **SiegePowerModifier**: *This setting is currently unused.* (Range:
  **0.01** to **10.0**)
- **DamageReceivedModifier**: Multiplier for all damage taken by the
  player vampire from any source. Lower values (\< 1.0) reduce damage
  taken. Default is **1.0**.
- **ReviveCancelDelay**: The time (in seconds) a player must wait after
  initiating a respawn/revive action before they are allowed to cancel
  it. Default is **5.0**.

Advertisement

### [UnitStatModifiers_Global Settings]

Contains settings that apply to regular
[Enemies](/wiki/Enemies "Enemies"), non-V Bloods. Default modifier is
1.0, default level increase is 0.\
**NOTE:** If your game\'s Difficulty Setting is set to a value other
than Normal, this setting will be overridden by preset values found in
the **Difficulty_Relaxed.json** or **Difficulty_Brutal.json** files in
the **GameDifficultyPresets** folder. You must instead change the preset
values If you wish to play Relaxed or Brutal Mode with different health
and power settings.

- **MaxHealthModifier**: Multiplier for the unit\'s base maximum health.
  (Range: **0.01** to **10.0**)
- **PowerModifier**: Multiplier for the unit\'s base power (affecting
  damage dealt by their attacks and abilities). (Range: **0.01** to
  **10.0**)
- **LevelIncrease**: A flat value added to the base level of the unit,
  increasing its overall stats and difficulty. (Range: **0** to **100**)

### [UnitStatModifiers_VBlood]

Contains settings that apply specifically to [V Blood
Carriers](/wiki/V_Blood_Carriers "V Blood Carriers"). Default modifier
is 1.0, default level increase is 0.\
**NOTE:** If your game\'s Difficulty Setting is set to a value other
than Normal, this setting will be overridden by preset values found in
the **Difficulty_Relaxed.json** or **Difficulty_Brutal.json** files in
the **GameDifficultyPresets** folder. You must instead change the preset
values If you wish to play Relaxed or Brutal Mode with different health
and power settings.

- **MaxHealthModifier**: Multiplier for the unit\'s base maximum health.
  (Range: **0.01** to **10.0**)
- **PowerModifier**: Multiplier for the unit\'s base power (affecting
  damage dealt by their attacks and abilities). (Range: **0.01** to
  **10.0**)
- **LevelIncrease**: A flat value added to the base level of the unit,
  increasing its overall stats and difficulty. (Range: **0** to **100**)

### [EquipmentStatModifiers_Global]

Contains settings that modify the effectiveness of stats granted by
equipped items (armor, weapons, jewelry).

Advertisement

#### [EquipmentStatModifier Settings]

Multiplicative modifiers applied to the stats granted by equipped items
(armor, weapons, jewelry). These settings are typically found under the
**EquipmentStatModifiers_Global** block. Default is 1.0 (no change).

- **MaxHealthModifier**: Multiplier for the Max Health bonuses provided
  by equipment. (Range: **0.01** to **10.0**)
- **ResourceYieldModifier**: Multiplier for Resource Yield bonuses
  provided by equipment (e.g., from Worker blood type bonus on gear).
  (Range: **0.01** to **10.0**)
- **PhysicalPowerModifier**: Multiplier for the Physical Power bonuses
  provided by equipment. (Range: **0.01** to **10.0**)
- **SpellPowerModifier**: Multiplier for the Spell Power bonuses
  provided by equipment. (Range: **0.01** to **10.0**)
- **SiegePowerModifier**: Multiplier for the Siege Power bonuses
  provided by equipment. (Range: **0.01** to **10.0**)
- **MovementSpeedModifier**: *This setting is currently unused.* (Range:
  **0.01** to **10.0**)

### [CastleStatModifiers_Global]

Contains settings that modify various limits and parameters related to
castle building and structures.

#### [CastleStatModifier Settings]

Modifiers and limits related to castle building, structure counts, and
decay mechanics. These settings are typically found under the
**CastleStatModifiers_Global** block.

- **TickPeriod**: How frequently (in seconds) the server checks Castle
  Heart status for Blood Essence consumption and decay processing.
  (Range: **0.1** to **600**)
- **SafetyBoxLimit**: Maximum number of Vampire Lockboxes (personal,
  secure storage) allowed per castle. (Range: **0** to **255**)
- **TombLimit**: Maximum number of Tombs (used for raising skeletons)
  allowed per castle. (Range: **0** to **255**)
- **EyeStructuresLimit**: Maximum number of Eye of Twilight structures
  (used for territory visibility) allowed per castle. (Range: **0** to
  **255**)
- **VerminNestLimit**: Maximum number of Vermin Nests (used for spawning
  rats/spiders) allowed per castle. (Range: **0** to **255**)
- **PrisonCellLimit**: Maximum number of Prison Cells (used for holding
  charmed humans) allowed per castle. (Range: **0** to **255**)
- **CastleLimit**: Maximum number of Castle Hearts (and thus separate
  castles) allowed per player or per clan, depending on
  **CastleHeartLimitType**. (Range: **0** to **255**, practical limit
  usually 1-5)
- **CastleHeartLimitType**: Determines whether the **CastleLimit**
  setting applies individually to each **User** or collectively to each
  **Clan**. (Enum: **User**, **Clan**)
- **HeartLimits**: An object containing specific structure limits based
  on the Castle Heart\'s current upgrade level. See [HeartLimits
  Structure](#HeartLimits_Structure) below.
- **NetherGateLimit**: Maximum number of Nether Gates (local
  teleporters) allowed per castle. (Range: **0** to **255**)
- **ThroneOfDarknessLimit**: Maximum number of Throne of Darkness
  structures (used for Servant Hunts) allowed per castle. (Range: **0**
  to **255**)

Advertisement

#### [HeartLimits Structure]

Defines structure limits based on the Castle Heart level. This object is
nested within [CastleStatModifier
Settings](#CastleStatModifier_Settings). It contains sub-objects named
**Level1**, **Level2**, **Level3**, **Level4**, and **Level5**. Each
sub-object contains the limits applicable when the Castle Heart reaches
that level, using the [HeartLevelLimit
Structure](#HeartLevelLimit_Structure) below. Example structure (within
CastleStatModifiers_Global):

    "HeartLimits": {
      "Level1": { "FloorLimit": 50, "ServantLimit": 4, "HeightLimit": 1 },
      "Level2": { "FloorLimit": 100, "ServantLimit": 5, "HeightLimit": 2 },
      "Level3": { "FloorLimit": 150, "ServantLimit": 6, "HeightLimit": 3 },
      "Level4": { "FloorLimit": 250, "ServantLimit": 7, "HeightLimit": 3 },
      "Level5": { "FloorLimit": 400, "ServantLimit": 9, "HeightLimit": 4 } // Example values

}

#### [HeartLevelLimit Structure]

These settings define the specific limits within each level object
(**Level1** through **Level5**) inside the [HeartLimits
Structure](#HeartLimits_Structure).

- **FloorLimit**: Maximum number of floor tiles allowed within the
  castle territory at this Heart level. (Value: number, e.g., 250. Range
  needs confirmation, likely 1 to \~500+)
- **ServantLimit**: Maximum number of Servant Coffins (and thus
  controllable Servants) allowed within the castle at this Heart level.
  (Range: **0** to **35**)
- **HeightLimit**: Maximum height in terms of wall levels (floors)
  allowed for castle construction at this Heart level. (Range: **0** to
  **255**, practical limit usually 3-4)

### [PlayerInteractionSettings]

Contains settings that define the specific time windows for PvP combat
and Castle Sieges when using TimeRestricted modes.

#### [PlayerInteraction Settings]

Settings controlling PvP and Castle Siege time restrictions, used when
**PlayerDamageMode** or **CastleDamageMode** are set to TimeRestricted.

- **TimeZone**: Specifies the time zone the server uses for calculating
  the start and end times of the windows below. **Local** uses the
  server machine\'s local time zone.

<!-- -->

* Enum values: Local, UTC, PST (UTC-7), EST (UTC-4), CET (UTC+1), CST (China Standard Time, UTC+8)

- **VSPlayerWeekdayTime**: Defines the active time window for Player vs
  Player damage during **weekdays** (Monday-Friday). Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure) below.
- **VSPlayerWeekendTime**: Defines the active time window for Player vs
  Player damage during **weekends** (Saturday-Sunday). Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure) below.
- **VSCastleWeekdayTime**: Defines the active time window for Castle
  damage (raiding) during **weekdays** (Monday-Friday). Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure) below.
- **VSCastleWeekendTime**: Defines the active time window for Castle
  damage (raiding) during **weekends** (Saturday-Sunday). Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure) below.

Advertisement

#### [StartEndTimeData Structure]

Defines a specific time window using start and end hours/minutes. Used
by [PlayerInteraction Settings](#PlayerInteraction_Settings) and
[WarEventGame Settings](#WarEventGame_Settings).

- **StartHour**: The hour (in 24-hour format) when the time window
  begins. (Range: **1** to **23**)
- **StartMinute**: The minute when the time window begins. (Range: **1**
  to **59**)
- **EndHour**: The hour (in 24-hour format) when the time window ends.
  (Range:: **1** to **23**)
- **EndMinute**: The minute when the time window ends. (Range: **1** to
  **59**)

### [TraderModifiers]

Contains settings modifying the behavior of NPC traders (stock quantity,
prices, restock speed).

#### [TraderModifier Settings]

Multiplicative modifiers affecting NPC merchants/traders found in the
world. Default is 1.0.

- **StockModifier**: Multiplier for the quantity of each item available
  in the trader\'s stock per restock cycle. (Range: **0.25** to
  **10.0**)
- **PriceModifier**: Multiplier for the cost (in Silver Coins or other
  currency) of items sold by the trader. (Range: **0.25** to **10.0**)
- **RestockTimerModifier**: Multiplier for the time it takes for the
  trader\'s inventory to fully restock. Lower values (\< 1.0) mean
  faster restocks. (Range: **0.25** to **10.0**)

### [**WarEventGameSettings**]

Contains settings controlling the frequency, duration, and timing of
world events like Rift Incursions.

#### [WarEventGame Settings]

Settings controlling the timing, frequency, and duration of world events
like [Rift Incursions](/wiki/Rift_Incursions "Rift Incursions")
(referred to as \"war events\" in the settings).

- **Interval**: Defines the approximate time duration between the start
  of consecutive war events (Incursions). Enum presets define frequency:
- Minimum: 30 minutes
- VeryShort: 1 hour
- Short: 1 hour 30 minutes
- Medium: 2 hours
- Long: 4 hours
- VeryLong: 8 hours
- Extensive: 12 hours
- Maximum: 24 hours
- **MajorDuration**: Defines the duration (length) of Major war events
  (Major Rift Incursions) once they begin. Enum presets define duration:
- Minimum: 15 minutes
- VeryShort: 20 minutes
- Short: 25 minutes
- Medium: 30 minutes
- Long: 35 minutes
- VeryLong: 45 minutes
- Extensive: 1 hour
- Maximum: 2 hours
- **MinorDuration**: Defines the duration (length) of Minor war events
  (Minor Rift Incursions) once they begin. Enum presets define duration:
- Minimum: 15 minutes
- VeryShort: 20 minutes
- Short: 25 minutes
- Medium: 30 minutes
- Long: 35 minutes
- VeryLong: 45 minutes
- Extensive: 1 hour
- Maximum: 2 hours
- **WeekDayTime**: Defines the time window during **weekdays**
  (Monday-Friday) when war events are allowed to spawn. Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure).
- **WeekendTime**: Defines the time window during **weekends**
  (Saturday-Sunday) when war events are allowed to spawn. Uses the
  [StartEndTimeData Structure](#StartEndTimeData_Structure).