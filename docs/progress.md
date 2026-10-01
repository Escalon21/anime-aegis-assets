# Anime Aegis TDS — progress (1 Oct 2026)

Place file: Documents\Anime Aegis TDS.rbxl. Claude edits Studio through the Roblox_Studio connector (Claude desktop app config).
UI designs live in the Claude Design artifact "Anime Aegis Lobby" (boards: Lobby layout, Lobby screen, Battle Gates, Lobby HUD v2, Units screen, Icon set, Summon screen, Summon x10 reveal, Battle HUD, Match results, Casual Brawler), Omar's Claude Design project with "Lobby HUD.dc.html" (current HUD, copy in github.com/Escalon21/anime-aegis-assets/lobby/hud), and Figma ("Anime Aegis - Play Screen v2", https://www.figma.com/design/OnraIFQeoGtsNO9Lel9fpM).
3D lobby pieces: Omar makes them with the Claude Design 3D beta from Claude's written brief and exports GLB; Claude checks them in Blender, places them by code. Claude's own Blender pieces (Summon Hall, Plaza Dressing) are FBX that Omar imports.
Working rule from Omar: anything Claude designs for a feature he asked for goes straight into the game. Characters are always original designs. Ask before adding anything new that wasn't requested.

## Done
1. Core TD: waves, server-side enemies, placement, upgrades/sell/targeting (GameServer, GameClient, GameConfig)
2. Units: ProfileService saving (DataManager, SummonServer, EquipServer)
3. Unit Bonds (BondService)
4. Dynamic Stage Events (StageEventService)
5. Story acts, Infinite, maps (MapService), rewards/levels, daily quests (QuestService, QuestGui)
6. Lobby: E-prompt stations, leaderboard (LobbyService, LobbyGui). Physical Battle Gates retired in 18; old generated plaza replaced by the imported pieces in 19
7. Aegis Mode: core + team upgrades, weekly modifiers, Shards + Shard Shop, Aegis Warden (AegisService, ShopServer)
8. Unit abilities: attack types, status effects, Support/Farm roles, active abilities, combat FX (CombatService); units Pop Idol, Merchant
9. Enemy traits: Flying, Hidden, Armor, Shield, Immune, boss abilities (EnemyTraits); enemies Harpy, Shadow, ArmoredKnight, ShieldGuard, DemonLord
10. Model + animation pipeline (ReplicatedStorage.VisualService + GameClient "UNIT VISUALS")
11. Unit progression (ProgressionService): unit copies with Uid, levels 1-50 + XP, traits, evolutions, feed, sell, lock, material drops
12. Claude Design UI: Lobby HUD v2, Units screen, stat potentials C..S+, 3 team presets, 37-icon sprite sheet (ReplicatedStorage.Icons, Sheet = rbxassetid://128914491575656; PNG in github.com/Escalon21/anime-aegis-assets/icons)
13. Summon screen + rotating banners, x1/x10 (1 Epic+), pity 50, auto-sell duplicate Rares, reveal, Unit Index, 100-unit cap
14. Battle HUD, 2x speed + Skip (party votes), results screen
15. Worlds, replay, quests, titles, tutorial, balance:
   - Own worlds: lobby at z=5000 (LobbyService O). Every map gets a themed landscape (MapService buildSurroundings). Lighting per player (StarterPlayerScripts.WorldLighting)
   - Live battle servers (ServerScriptService.BattleServers, Config.UseBattleServers): reserved private server per launch, teleport back after. Sub-place ready: set Config.BattlePlaceId once a Battle place exists (deferred). NOT testable in Studio
   - Replay / Next Act / Lobby on the results screen (Remotes.PostMatchChoice, Config.PostMatchSeconds = 10)
   - Quests panel restyled; Titles (Config.Titles, TitleService, EquipTitle); Tutorial (TutorialClient, StarterGiftGems 300)
   - Balance: Act 1 HpScale 0.85. Splitter, StormTitan, Act 4: Frozen Peaks, title Peak Conqueror
   - Test hooks: GameClient.DebugSelect, SummonScreen.PreviewReveal, PlayGui.PlayClient.DebugPlay, ServerStorage.DebugData (Studio only, see Testing)
16. Aegis rarity + R6 towers + first Aegis unit:
   - Rarity Aegis (cyan) never summoned; drops only in Aegis Mode (Config.AegisUnit, from wave 10, 0.1% per wave). Evolution item "Hero Emblem" (Aegis Mode only, 25%)
   - Towers are R6 (VisualService.BuildFallbackRig) at 0.75 scale
   - "Casual Brawler" (original design). Model ReplicatedStorage.UnitModels.AegisChampion, v2 from 69 parts. Lv3 "Lazy Haymaker"
17. Summon Hall (Blender) - LIVE:
   - Files in github.com/Escalon21/anime-aegis-assets/lobby/summon_hall (summon_hall.py, SummonHall.fbx/.blend, scripts)
   - Name contract: <Name>__<style>; Wall_/Floor_/Roof_ solid; DoorL/DoorR slide; Spin_* rings rotate; MK_* markers
   - Workspace.SummonHall; SummonHallService moves it into place facing the spawn, styles it, door, banner screen, summoner -> Summon panel
18. Play screen (replaces the physical Battle Gates):
   - v2 = Figma redesign (StarterGui.PlayGui.PlayClient; v1 kept disabled as PlayClient_v1_backup). Slanted anime cards, speed-line background, party stage, pulsing "+" invite slots, slanted Back / Invite / Join Party, full motion pass
   - Roblox tricks: slanted shapes = UIGradient transparency cut; frames wider than 4.6:1 are built from 2 caps + a middle strip; text can't render above 100px
   - LobbyService "Parties": remotes Party, PartyUpdate, PartyInvite; ChooseMode -> countdown (3s solo, 6s party) -> OnLaunch. Tested solo; multiplayer invites not tested yet (Studio Test > 2 players)
19. New lobby from the Claude Design 3D beta (GLB), in github.com/Escalon21/anime-aegis-assets/lobby/pieces - LIVE:
   - Border, PlazaGround, AegisCore, SpawnPad, UnitHangar, QuestBond, TopWaves, AegisShop
   - SummonHallService "lobby pieces": Models with MK_Center are styled and placed by PIECE_SPOTS (lobby coords, +Z south). MK_Station_<Panel> -> E prompt + click. MK_Screen_TopWaves = live leaderboard, MK_Screen_Quests = quest board
   - LobbyService: with PlazaGround present the old generated plaza is skipped; only an invisible spawn on the Spawn Pad + BorderFloor safety floor
20. Map + lighting pass: LOBBY_SCALE = 1.25 (building size)
21. Lobby HUD v5 - LIVE in StarterGui.LobbyGui.LobbyClient (old HUD kept disabled as LobbyClient_v2_backup):
   - Built 1:1 from "Lobby HUD.dc.html": design px at 1080p (UIScale = min(screenH/1080, screenW/1250)), palette #16181F/#262A35/#E4E7EF/#3a3f52 + pink FF3FA4, amber FFB23F, teal 38F2C0, red E8413A, lavender 8E86C9
   - Font: design uses Chakra Petch (not in Roblox) -> Sarpanch Heavy/Bold (its "a" looks like "o" at small sizes; nameplates use FredokaOne/Gotham instead)
   - Clip-path corners (top-left + bottom-right cut) = rectangles + 2 UIGradient-cut triangle squares (helper `cut`)
   - Left grid (Aegis Shop, Units H, Items J, Quests K + badge, Summon G, Bonds, PLAY, Events + LIVE), right column (Aegis Pass, Top Waves, Profile, Daily), top-right trophy | UPD 1 (What's New panel), bottom gem / ¥ Coins / Shards chips, settings gear, 6 team cards, 10-tick XP bar, design-style toast
   - Icons: ReplicatedStorage.HudIcons (sheet in HudIcons.Sheet.Image, tinted in code); emoji stand-ins until uploaded
22. Units + animated previews - LIVE:
   - 8 original unit models built from parts (ServerStorage.RigBuilder helpers, units/build_units.lua): Blade, Gunner, Mage (Storm Caller), Ninja, Dragon, AegisWarden, Idol, Merchant -> ReplicatedStorage.UnitModels (cards, inventory, placement and battle)
   - ReplicatedStorage.UnitPreview: ViewportFrame + WorldModel; real Idle animation if Visual.Animations.Idle exists, otherwise procedural idle; only animates on-screen previews; Pooled(key) cache for lists that get rebuilt
   - HUD team cards show the live unit; Units inventory cards = rarity gradient + rarity frame + live unit; detail panel = full-body preview (UnitsClient_backup kept disabled)
23. Bigger lobby + NPCs - LIVE:
   - LOBBY_SPREAD = 1.6 in SummonHallService + LobbyService (SummonHallService_backup kept disabled)
   - 10 original NPCs (units/build_npcs.lua -> ReplicatedStorage.LobbyNPCs): Oracle Lumi, Kaito, Mira, Chief Rook, Pim, Sora, Blaze, Yuki, Vex, Madam Coin
   - SummonHallService.spawnNPC: floor raycast, nameplate, key lights, tag "LobbyNPC"; SummonHallFX (client): NPC idle + head turns toward the player
24. Blender plaza dressing (lobby/dressing/plaza_dressing.py -> PlazaDressing.fbx). PIECE_SPOTS "PlazaDressing" (Fixed = no scaling). Needs Omar to import it
25. 3D HUD icons (icons/hud/render_icons3d.py -> HudIcons3D.png). Needs Omar to upload it into ReplicatedStorage.HudIcons.Sheet
26. Lobby lighting balance: brighter ambient (WorldLighting LOBBY: Ambient 122,116,168, Brightness 2.4, Exposure 0.3, ColorCorrection "LobbyGrade"), softer bloom (0.16 / 12 / 3.2), neon styles dimmed and border neon 45% darker
27. Daily login rewards: Config.DailyRewards (7 days, day 7 = 10 Tickets + 250 Gems), DailyService (RemoteFunction ClaimDaily, attribute "Daily"), Daily panel. SummonTickets pay for pulls before gems
28. Settings: ReplicatedStorage.ClientSettings (Music, SFX, LowFX, DamageNumbers, HideOthers, Auto2x, KeyHints, SummonAutoSell, SummonSkip, SummonAutoLock), saved by SettingsService (SaveSettings)
29. ¥ Coins: Config.Coins (start 500, per wave, story win/loss), used to feed units (Config.FeedCoinCost); results screen shows ¥
30. Sound + music: ReplicatedStorage.Sfx (licensed Roblox/APM/ProSoundEffects/DistroKid audio only), AudioClient (lobby/battle/boss music crossfade, attack sounds per unit, stings, every button clicks)
31. Battle QoL: AUTO-UPGRADE toggle in the unit panel (remote SetAutoUpgrade; queued units upgrade in the order you queued them, saving up for the first one), 3x speed (MatchVote "Speed3", unlocks at Config.Speed3Level = 15; speed button cycles 1x -> 2x -> 3x). Hotkeys 1-6 + Replay were already in
32. Summon polish: live 3D units on banner / reveal / index cards, full-screen rarity cut-in for Legendary+ pulls (tap to skip), Tickets pill + "free" labels on the summon buttons, toggles saved in settings, auto-lock Legendary+ pulls, Summon History panel (last 50 pulls saved in SummonHistory)
33. Collection rewards: Config.IndexRewards (discover 3 / 5 units, rarity sets, Mythic find, 4 bond sets, full index -> title "Archivist"), IndexRewardService (ClaimIndexReward), Discovered list (ever owned, selling doesn't undo it). Unit Index shows silhouettes for undiscovered units + a rewards column; red dot when something is ready
34. Attack animations + hit FX: ReplicatedStorage.BattleFX - procedural attacks for the jointed rigs (Slash, Dash, Heavy, Punch, Shot, Toss, Magic, Cheer, Breath per unit), battle idle, muzzle flash / spell glow / sword arcs, hit sparks, white hit flash, damage numbers (gold for big hits), death bursts, camera shake on bosses + nukes. LowFX and DamageNumbers settings respected
35. Challenge mode: Config.Challenges - rotates every 30 min, a Story act + one twist (Glass Cannon, Iron Hide, Shoestring, Elite Only, Fragile Core, Swarm, Small Squad). GameServer "Rules" table applies them. First clear per rotation: 150 Gems + 1 Trait Crystal; every clear ¥300 + 200 XP. Needs Act 1
36. Boss Rush: Config.BossRush - 8 boss waves with escorts on Demon's Keep, $1800 start. Gems/XP/¥ per wave, full clear +400 Gems + 40 Shards, best saved (BestBossRush). Needs Act 2
37. Aegis Pass (free Season 1 "Neon Dawn"): Config.AegisPass - 30 tiers, 600 XP each; XP from waves, wins, quests, daily logins and summons (PassService.AddXP). Pass panel with the track, Claim / Claim All, tier-up toast; last tier unlocks title "Neon Vanguard". No paid track (would need a Game Pass id)
38. Raid (co-op): Config.Raid - 6 elite waves on Frozen Peaks ending with Demon Lord + Storm Titan, $1200 start, best with 3+ players. Weekly first clear +600 Gems + 5 Tickets (RaidWeek). Needs Act 3
   - Play screen: Raid / Boss Rush / Challenge tiles are live with their own detail pages; Profile shows Boss Rush + Raid bests; What's New lists the update
39. Global leaderboards: ServerScriptService.GlobalBoards (OrderedDataStores Board_Infinite / Board_Aegis / Board_BossRush / Board_Raid). Bests are written when they improve (batched every 30s), top 25 read every 2 min into ReplicatedStorage attribute "GlobalBoards". Leaderboards panel has tabs (This server / Infinite / Aegis / Boss Rush / Raid); the 3D Top Waves screen shows the global Infinite board
40. Act 5: Neon Abyss (map NeonAbyss, HpScale 2.8, needs Act 4) with new original enemies Glitch (tiny, fast, hidden), Bulwark (armor + shield wall, slow-immune), Hive (bursts into 4 Glitches) and boss Abyss Sovereign (shield, heals, summons Bulwarks, stuns towers, enrages). Title "Abyss Walker". Added to the Challenge rotation; Story list scrolls
41. Achievements: Config.Achievements (16 goals: kills, bosses, summons, placements, bonds, story wins, levels, Infinite 30, Boss Rush + Raid clears). Lifetime counters d.Stats are fed by QuestService.Progress (start counting from this update). AchievementService (ClaimAchievement); listed at the bottom of Profile with progress bars + Claim; red dot on the Profile tile
42. Premium Aegis Pass track: every tier has a Premium reward (gold band on the card); one Claim takes both. Unlocked by a Game Pass: set Config.AegisPass.PremiumGamePassId (0 = "coming soon"). PassService checks ownership on join + after purchase (attribute PassPremium); "UNLOCK PREMIUM" button prompts the purchase
44. Evolved looks (Mythic / Secret / Aegis only, Config.EvolvedLookRarities): units/build_evolved.lua builds UnitModels.Dragon_Evolved ("Elder Dragon": obsidian + molten gold, crown, magma-veined wings, flame crests, ember aura) and UnitModels.AegisChampion_Evolved ("Casual Brawler (Awakened)": white + cyan, eyes open and glowing, floating halo, Aegis emblem, aura). An evolved copy uses the new model in battle (unit attribute Evolved), on Units cards, the detail preview and the HUD team cards. Elder Dragon stats raised (x1.45 dmg). No Secret unit exists yet. The older stat-only evolutions of Rare/Epic units were left as they were
45. Balance bot (ServerStorage.DevTools.BalanceBot, repo tools/balance_bot.lua) + DebugData "snapshot" / "restore" / "keeplevel". Results and fixes (balance pass 2, end of GameConfig):
   - Act 1-2: cleared by both a Rare team and a Mythic/Epic team
   - Act 3-5 died on wave 2 for every team -> per-act StartCash (Act2 700, Act3 1000, Act4 1300, Act5 1600), gentler HP steps (Act3 1.4, Act4 1.8, Act5 2.2), softer early/mid waves (fewer Brutes in Act 3, lighter Act 4 waves 1-4, Act 5 waves 1-4)
   - Mythic/Epic attackers were weaker per slot than Rare Ninja/Gunner -> Dragon and Storm Caller buffed, Aegis Warden L3 buffed, Ninja L2/L3 nerfed
   - Bosses no longer one-shot the base (Boss 40, Demon Lord 60, Storm Titan 70, Abyss Sovereign 80 of 100 HP); mid-act Boss HP 3500 -> 3000
   - After the fixes the bot (level-1 units, no abilities) reaches wave 6-7 in Act 3 and wave 6 in Act 4; stage events make single runs noisy. Boss Rush with level-1 units ends around wave 3
43. Mode tutorials: ReplicatedStorage.FirstTips - one-time "NEW!" cards for Challenge, Boss Rush, Raid (Play screen detail), Aegis Pass (panel) and Collection rewards (Unit Index). Remembered in ClientSettings.SeenTips

## How to add a real unit/enemy model
1. Put a rigged Model (HumanoidRootPart + Humanoid or AnimationController, Motor6D joints) in ReplicatedStorage.UnitModels (or EnemyModels), named after the unit id (e.g. "Blade") - or rebuild with units/build_units.lua.
2. Upload animations (owned by you / your group) and add to GameConfig:
   Config.Units.Blade.Visual = { Model = "Blade", Scale = 1, Animations = { Idle = "rbxassetid://ID", Attack = { "rbxassetid://ID" }, Place = "...", Ability = "...", Upgrade = "..." } }
   Units with a real Idle animation skip the BattleFX procedural animation automatically.
3. New unit attack style: BattleFX.Styles[unitId] = "Slash" | "Dash" | "Heavy" | "Punch" | "Shot" | "Toss" | "Magic" | "Cheer" | "Breath"

## How to add new icons
Game icons: add the SVG to the icon script, re-render the sheet (8 x 128px columns), then Omar uploads it (ReplicatedStorage.Icons.Sheet > Image > Add Image). HUD icons: add the Material Symbols name to HudIcons NAMES + render_icons3d.py, re-render, re-upload into ReplicatedStorage.HudIcons.Sheet. Claude can't upload images itself (CreateAssetAsync not available, upload_image only trusts some URLs).

## Testing
- Never require DataManager (or anything that requires it) from the Studio command bar / execute_luau: it makes a second copy that loads the profile again. Use ServerStorage.DebugData:Invoke(player, "add" | "set" | "get", key, value) instead (Studio only)
- Start a match from the client: ReplicatedStorage.StartMatch:InvokeServer("Story", "Act1" | "Infinite" | "Aegis" | "Challenge" | "BossRush" | "Raid")

## Next
- Omar: upload icons/hud/HudIcons3D.png into ReplicatedStorage.HudIcons.Sheet; import lobby/dressing/PlazaDressing.fbx; Ctrl+S
- Ticket icon for the HUD sheets (summon screen shows text for now)
- Omar: create the Premium Pass Game Pass and put its id in Config.AegisPass.PremiumGamePassId
- Real animations for units/NPCs (BattleFX procedural for now)
- Test party invites + Raid with 2+ players
- Heroes vs Villains release: original Mythic units
- Sub-places (Battle place + Config.BattlePlaceId)

## Known limits
- Battle servers only work in a published game (TeleportService); first live test still to do
- At 2x/3x, burn ticks, stuns, rage and ability cooldowns still run in real time
- Act 2-4, Challenge, Boss Rush and Raid balance not bot-tested yet; Challenge can land on Act 3/4 for new players
- Studio viewport screenshots sometimes come back blank when Studio isn't visible
