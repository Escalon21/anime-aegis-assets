-- Builds the lobby NPCs into ReplicatedStorage.LobbyNPCs (original characters). Attributes: DisplayName, Title, NameColor, TitleColor.
local R = require(game.ServerStorage.RigBuilder)
local H, V, A, at, NEON, METAL = R.H, R.V, R.A, R.at, R.NEON, R.METAL
local rig, att, rod, ball, disc, eyes, hairBase, spikes, bangs, sleeves, boots = R.rig, R.att, R.rod, R.ball, R.disc, R.eyes, R.hairBase, R.spikes, R.bangs, R.sleeves, R.boots

local folder = game.ReplicatedStorage:FindFirstChild("LobbyNPCs") or Instance.new("Folder")
folder.Name = "LobbyNPCs"
folder.Parent = game.ReplicatedStorage

local npcs = {}
local function tag(m, name, title, nameColor, titleColor)
	m:SetAttribute("DisplayName", name)
	m:SetAttribute("Title", title)
	m:SetAttribute("NameColor", nameColor)
	m:SetAttribute("TitleColor", titleColor or H("E4E7EF"))
	return m
end

-- Oracle Lumi: the Summoner (starry robes, halo rings, summoning crystal)
npcs.Summoner = function()
	local m, P = rig("Summoner", { skin = H("F8DCCB"), shirt = H("2A2466"), pants = H("2A2466"), arms = H("2A2466") })
	local T, Hd = P.Torso, P.Head
	local gold, star, lav = H("E8C35A"), H("CFF6FF"), H("B9B3EC")
	att(m, T, "Stole", V(0.5, 2.05, 1.08), lav, at(0, 0, 0))
	att(m, T, "StoleGem", V(0.26, 0.26, 0.08), H("8EE8FF"), at(0, 0.5, -0.57, 0, 0, 45), { mat = NEON })
	att(m, T, "Sash", V(2.08, 0.26, 1.08), gold, at(0, -0.7, 0), { mat = METAL })
	for i, p in ipairs({ V(-0.6, 0.3), V(0.7, -0.2), V(-0.4, -0.35), V(0.55, 0.6) }) do att(m, T, "Star" .. i, V(0.12, 0.12, 0.04), star, at(p.X, p.Y, -0.53, 0, 0, 45), { mat = NEON }) end
	att(m, T, "RobeF", V(2.2, 2.0, 0.12), H("2A2466"), at(0, -1.95, -0.6, -5, 0, 0))
	att(m, T, "RobeB", V(2.2, 2.0, 0.12), H("2A2466"), at(0, -1.95, 0.6, 5, 0, 0))
	att(m, T, "RobeL", V(0.12, 2.0, 1.2), H("221E58"), at(-1.1, -1.95, 0, 0, 0, -5))
	att(m, T, "RobeR", V(0.12, 2.0, 1.2), H("221E58"), at(1.1, -1.95, 0, 0, 0, 5))
	att(m, T, "Hem", V(2.3, 0.1, 0.16), gold, at(0, -2.93, -0.7, -5, 0, 0), { mat = METAL })
	att(m, T, "Cape", V(2.1, 3.6, 0.1), H("3A3288"), at(0, -0.75, 0.62, 5, 0, 0))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Bell", V(1.36, 0.7, 1.36), H("3A3288"), at(0, -0.5, 0))
		att(m, P[a], "BellTrim", V(1.4, 0.1, 1.4), gold, at(0, -0.85, 0), { mat = METAL })
		att(m, P[a], "Hand", V(0.8, 0.35, 0.8), H("F8DCCB"), at(0, -1.0, 0))
	end
	-- summoning crystal floating over the right hand
	att(m, P["Right Arm"], "Crystal", V(0.45, 0.8, 0.45), H("8EE8FF"), at(0, -1.7, -0.5, 0, 45, 0), { mat = NEON })
	disc(m, P["Right Arm"], "CrystalRing", 0.05, 1.0, gold, at(0, -1.7, -0.5), { mat = NEON })
	eyes(m, Hd, H("B9B3EC"), { glow = true, h = 0.32, lash = H("3A2E6A"), mouthW = 0.12 })
	hairBase(m, Hd, H("CFC6FF"), { backH = 2.0, sideH = 1.0 })
	att(m, Hd, "LockL", V(0.26, 1.5, 0.36), H("CFC6FF"), at(-0.6, -0.4, -0.3))
	att(m, Hd, "LockR", V(0.26, 1.5, 0.36), H("CFC6FF"), at(0.6, -0.4, -0.3))
	bangs(m, Hd, H("CFC6FF"), H("B0A6F0"), 6, 0.42, 0.42)
	disc(m, Hd, "Halo", 0.06, 1.9, gold, at(0, 1.05, 0.35, -20, 0, 0), { mat = NEON })
	disc(m, Hd, "Halo2", 0.05, 1.4, H("8EE8FF"), at(0, 1.05, 0.35, -20, 0, 0), { mat = NEON })
	att(m, Hd, "Tiara", V(0.3, 0.3, 0.06), H("8EE8FF"), at(0, 0.45, -0.7, 0, 0, 45), { mat = NEON })
	return tag(m, "Oracle Lumi", "Keeper of the Gate", H("B9B3EC"), H("8EE8FF"))
end

-- Kaito: guest in the hall, sporty rookie in a teal jacket
npcs.HallGuestL = function()
	local m, P = rig("HallGuestL", { skin = H("EBC29A"), shirt = H("1FA88C"), pants = H("2A3044"), arms = H("1FA88C") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Tee", V(0.7, 1.8, 0.04), H("F2F4F7"), at(0, 0.05, -0.525))
	att(m, T, "Stripe", V(2.04, 0.2, 1.04), H("F2F4F7"), at(0, 0.3, 0))
	att(m, T, "Hem", V(2.04, 0.22, 1.04), H("16806A"), at(0, -0.88, 0))
	sleeves(m, P, H("1FA88C"), H("F2F4F7"), 1.4)
	boots(m, P, H("F2F4F7"), H("E8413A"), 0.45)
	eyes(m, Hd, H("3A2A1E"), { brow = H("2A1E14"), browTilt = -4, mouthW = 0.2, mouthColor = H("A04A4A") })
	hairBase(m, Hd, H("2A1E14"))
	spikes(m, Hd, { { -0.4, 0.8, 0.1, -20, 0, 25, 0.4, 0.5, 0.4 }, { 0.05, 0.85, 0.05, -25, 0, 0, 0.45, 0.55, 0.45 }, { 0.45, 0.8, 0.1, -20, 0, -25, 0.4, 0.5, 0.4 } }, H("2A1E14"), H("3A2A1E"))
	bangs(m, Hd, H("2A1E14"), H("3A2A1E"), 4, 0.4, 0.34)
	disc(m, Hd, "CapBrimless", 0.06, 1.36, H("E8413A"), at(0, 0.36, 0.02))
	return tag(m, "Kaito", "Rookie Defender", H("38F2C0"))
end

-- Mira: guest in the hall, banner hunter with a lucky charm
npcs.HallGuestR = function()
	local m, P = rig("HallGuestR", { skin = H("F8D8C8"), shirt = H("E8413A"), pants = H("1E2230"), arms = H("F8D8C8") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Collar", V(1.5, 0.4, 1.12), H("F2F4F7"), at(0, 0.8, 0))
	att(m, T, "Tie", V(0.22, 0.7, 0.06), H("FFB23F"), at(0, 0.3, -0.54))
	att(m, T, "Skirt", V(2.2, 0.7, 1.2), H("1E2230"), at(0, -1.2, 0))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do att(m, P[a], "Sleeve", V(1.08, 0.7, 1.08), H("E8413A"), at(0, 0.65, 0)) end
	att(m, P["Left Arm"], "Charm", V(0.3, 0.3, 0.06), H("FFB23F"), at(0, -1.25, -0.4, 0, 0, 45), { mat = NEON })
	boots(m, P, H("1E2230"), H("0E1018"), 0.9)
	eyes(m, Hd, H("FFB23F"), { h = 0.32, lash = H("3A1E1E"), mouthW = 0.12 })
	hairBase(m, Hd, H("F2D06A"), { backH = 1.3, sideH = 0.8 })
	bangs(m, Hd, H("F2D06A"), H("E0B84A"), 5, 0.42, 0.4)
	ball(m, Hd, "Bun", 0.7, H("F2D06A"), at(0, 0.7, 0.45))
	return tag(m, "Mira", "Banner Hunter", H("FFB23F"))
end

-- Chief Rook: runs the Unit Hangar (mechanic, goggles, overalls, big wrench)
npcs.HangarChief = function()
	local m, P = rig("HangarChief", { skin = H("C99A72"), shirt = H("3A6EA8"), pants = H("3A6EA8"), arms = H("C99A72") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Tank", V(1.4, 1.2, 0.04), H("F2F4F7"), at(0, 0.45, -0.52))
	att(m, T, "BibL", V(0.2, 1.3, 0.06), H("2E5A8C"), at(-0.55, 0.35, -0.53))
	att(m, T, "BibR", V(0.2, 1.3, 0.06), H("2E5A8C"), at(0.55, 0.35, -0.53))
	att(m, T, "Pocket", V(0.8, 0.5, 0.06), H("2E5A8C"), at(0, -0.3, -0.53))
	att(m, T, "ToolBelt", V(2.1, 0.26, 1.1), H("5A3A22"), at(0, -0.8, 0))
	att(m, T, "Rag", V(0.25, 0.6, 0.05), H("E8413A"), at(0.8, -1.1, -0.56))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do att(m, P[a], "Glove", V(1.08, 0.6, 1.08), H("FFB23F"), at(0, -0.7, 0)) end
	-- wrench on the shoulder
	local ra = P["Right Arm"]
	rod(m, ra, "Wrench", V(0, -1.05, -0.1), V(0, 1.4, 0.6), 0.2, H("8E9AAA"), { mat = METAL })
	att(m, ra, "WrenchHead", V(0.6, 0.25, 0.45), H("8E9AAA"), at(0, 1.5, 0.65, -20, 0, 0), { mat = METAL })
	boots(m, P, H("3A2A1E"), H("1A120C"), 0.7)
	eyes(m, Hd, H("3A2A1E"), { brow = H("E0E0E0"), browTilt = 8, mouthW = 0.22 })
	att(m, Hd, "Beard", V(1.2, 0.5, 0.3), H("E0E0E0"), at(0, -0.4, -0.5))
	att(m, Hd, "Mustache", V(0.6, 0.12, 0.08), H("E0E0E0"), at(0, -0.18, -0.64))
	hairBase(m, Hd, H("E0E0E0"), { backH = 0.6 })
	disc(m, Hd, "GoggleL", 0.14, 0.4, H("FFB23F"), at(-0.25, 0.5, -0.64, 90, 0, 0), { mat = NEON })
	disc(m, Hd, "GoggleR", 0.14, 0.4, H("FFB23F"), at(0.25, 0.5, -0.64, 90, 0, 0), { mat = NEON })
	att(m, Hd, "GoggleStrap", V(1.38, 0.14, 1.38), H("3A2A1E"), at(0, 0.5, 0))
	return tag(m, "Chief Rook", "Unit Hangar Chief", H("FFB23F"))
end

-- Pim: the Quartermaster (apron, crate on the shoulder)
npcs.Quartermaster = function()
	local m, P = rig("Quartermaster", { skin = H("F2C9A0"), shirt = H("6A8A4A"), pants = H("4A3A2A") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Apron", V(1.6, 2.4, 0.06), H("C8A878"), at(0, -0.4, -0.53))
	att(m, T, "ApronPocket", V(0.9, 0.4, 0.05), H("A88858"), at(0, -0.5, -0.57))
	sleeves(m, P, H("6A8A4A"), H("4A6A2A"), 1.1)
	att(m, P["Left Arm"], "Crate", V(1.4, 1.1, 1.2), H("A8743A"), at(0, 1.3, 0.1))
	att(m, P["Left Arm"], "CrateBand", V(1.44, 0.14, 1.24), H("5A3A22"), at(0, 1.3, 0.1))
	att(m, P["Left Arm"], "CrateGlow", V(0.4, 0.4, 0.05), H("38F2C0"), at(0, 1.3, -0.52), { mat = NEON })
	boots(m, P, H("4A3A2A"), H("22180E"), 0.5)
	eyes(m, Hd, H("6A8A4A"), { brow = H("B8741E"), mouthW = 0.18 })
	hairBase(m, Hd, H("D08A3A"))
	bangs(m, Hd, H("D08A3A"), H("B87428"), 5, 0.4, 0.36)
	disc(m, Hd, "Bandana", 0.16, 1.4, H("E8413A"), at(0, 0.45, 0.02))
	return tag(m, "Pim", "Quartermaster", H("38F2C0"))
end

-- Sora: Quest Board clerk (beret, clipboard)
npcs.QuestClerk = function()
	local m, P = rig("QuestClerk", { skin = H("F8D8C8"), shirt = H("F2F4F7"), pants = H("2A3044") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Vest", V(2.06, 1.6, 1.06), H("E8413A"), at(0, 0.2, 0))
	att(m, T, "VestGap", V(0.4, 1.6, 0.04), H("F2F4F7"), at(0, 0.2, -0.54))
	att(m, T, "Badge", V(0.3, 0.3, 0.05), H("FFB23F"), at(-0.55, 0.5, -0.56), { mat = NEON })
	att(m, T, "Skirt", V(2.1, 0.6, 1.1), H("2A3044"), at(0, -1.1, 0))
	att(m, P["Left Arm"], "Clipboard", V(0.9, 1.1, 0.08), H("8A5A2A"), at(0.1, -1.0, -0.6, -20, 0, 0))
	att(m, P["Left Arm"], "Paper", V(0.75, 0.9, 0.04), H("F2F4F7"), at(0.1, -1.0, -0.66, -20, 0, 0))
	rod(m, P["Right Arm"], "Pen", V(0, -1.1, -0.2), V(0, -0.8, -0.6), 0.06, H("E8413A"))
	boots(m, P, H("2A3044"), H("0E1018"), 0.6)
	eyes(m, Hd, H("3A6EA8"), { h = 0.3, lash = H("2A1E14"), mouthW = 0.12 })
	hairBase(m, Hd, H("3A2A1E"), { backH = 0.9, sideH = 0.8 })
	bangs(m, Hd, H("3A2A1E"), H("4A3A2A"), 5, 0.42, 0.4)
	disc(m, Hd, "Beret", 0.25, 1.5, H("E8413A"), at(0.1, 0.72, 0.05, 0, 0, -10))
	return tag(m, "Sora", "Quest Board Clerk", H("E8413A"))
end

-- Blaze: Event Herald (flashy jacket, megaphone)
npcs.EventHerald = function()
	local m, P = rig("EventHerald", { skin = H("C99A72"), shirt = H("FF7A2E"), pants = H("1E2230"), arms = H("FF7A2E") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Inner", V(0.7, 1.8, 0.04), H("16181F"), at(0, 0.05, -0.525))
	att(m, T, "FlameL", V(0.4, 0.8, 0.05), H("FFE14D"), at(-0.7, -0.5, -0.53, 0, 0, 20), { cls = "WedgePart" })
	att(m, T, "FlameR", V(0.4, 0.8, 0.05), H("FFE14D"), at(0.7, -0.5, -0.53, 0, 0, -20), { cls = "WedgePart" })
	att(m, T, "Chain", V(0.9, 0.08, 0.05), H("E8C35A"), at(0, 0.6, -0.56, 0, 0, 10), { mat = METAL })
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do att(m, P[a], "Cuff", V(1.12, 0.3, 1.12), H("16181F"), at(0, -0.5, 0)) end
	local ra = P["Right Arm"]
	rod(m, ra, "MegaHandle", V(0, -1.05, -0.1), V(0, -1.05, -0.6), 0.2, H("16181F"))
	rod(m, ra, "Megaphone", V(0, -0.95, -0.6), V(0, -0.7, -1.6), 0.55, H("F2F4F7"))
	att(m, ra, "MegaRim", V(0.8, 0.8, 0.1), H("FF7A2E"), at(0, -0.68, -1.62, -15, 0, 0))
	boots(m, P, H("F2F4F7"), H("FF7A2E"), 0.5)
	eyes(m, Hd, H("FF7A2E"), { brow = H("16181F"), browTilt = -6, mouthW = 0.24, mouthH = 0.08, mouthColor = H("5A1E1E") })
	hairBase(m, Hd, H("16181F"), { backH = 0.5 })
	spikes(m, Hd, { { 0, 0.95, -0.1, -40, 0, 0, 0.5, 0.9, 0.45 }, { 0, 0.9, 0.3, 10, 0, 0, 0.5, 0.8, 0.45 } }, H("FF7A2E"), H("FFB23F"))
	att(m, Hd, "Shades", V(1.0, 0.18, 0.06), H("16181F"), at(0, 0.05, -0.64))
	att(m, Hd, "ShadeGlint", V(0.2, 0.05, 0.04), H("FFFFFF"), at(-0.2, 0.1, -0.68), { mat = NEON })
	return tag(m, "Blaze", "Event Herald", H("FF7A2E"), H("FFE14D"))
end

-- Yuki: Bond Shrine keeper (shrine maiden red and white, ribbon charm)
npcs.BondKeeper = function()
	local m, P = rig("BondKeeper", { skin = H("F8DCCB"), shirt = H("F4F2EC"), pants = H("C8242E"), arms = H("F4F2EC") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "CollarL", V(0.26, 1.2, 0.06), H("C8242E"), at(-0.25, 0.45, -0.53, 0, 0, -22))
	att(m, T, "CollarR", V(0.26, 1.2, 0.06), H("C8242E"), at(0.25, 0.45, -0.53, 0, 0, 22))
	att(m, T, "Obi", V(2.08, 0.34, 1.08), H("C8242E"), at(0, -0.75, 0))
	att(m, T, "Bow", V(0.6, 0.35, 0.2), H("FF3FA4"), at(0, -0.75, 0.62))
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do att(m, P[l], "Hakama", V(1.16, 1.7, 1.16), H("C8242E"), at(0, 0.15, 0)) end
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do att(m, P[a], "Sleeve", V(1.3, 1.5, 1.5), H("F4F2EC"), at(0, 0.1, 0.2)) end
	-- ribbon charm linking two bells (the "bond")
	local la = P["Left Arm"]
	rod(m, la, "Ribbon", V(0, -1.1, -0.3), V(0, -1.9, -0.5), 0.05, H("FF3FA4"), { w = 0.18 })
	ball(m, la, "BellA", 0.26, H("E8C35A"), at(-0.12, -1.95, -0.52), { mat = METAL })
	ball(m, la, "BellB", 0.26, H("E8C35A"), at(0.12, -1.95, -0.48), { mat = METAL })
	boots(m, P, H("F4F2EC"), H("5A3A22"), 0.3)
	eyes(m, Hd, H("C8242E"), { h = 0.3, lash = H("1E1820"), mouthW = 0.1 })
	hairBase(m, Hd, H("16181F"), { backH = 2.2, sideH = 1.0 })
	bangs(m, Hd, H("16181F"), H("2A2A36"), 6, 0.42, 0.44)
	att(m, Hd, "HairTie", V(0.5, 0.2, 0.1), H("F4F2EC"), at(0, -0.4, 0.72))
	att(m, Hd, "Ornament", V(0.3, 0.3, 0.05), H("FF3FA4"), at(0.55, 0.45, -0.3, 0, 0, 45), { mat = NEON })
	return tag(m, "Yuki", "Bond Shrine Keeper", H("FF3FA4"))
end

-- Vex: Rank Announcer at Top Waves (headset, cap, trophy)
npcs.RankAnnouncer = function()
	local m, P = rig("RankAnnouncer", { skin = H("E8B48E"), shirt = H("8E86C9"), pants = H("2A3044"), arms = H("8E86C9") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Zip", V(0.08, 1.9, 0.05), H("E4E7EF"), at(0, 0, -0.53))
	att(m, T, "Number", V(0.7, 0.6, 0.04), H("38F2C0"), at(0.5, 0.35, -0.525), { mat = NEON })
	att(m, T, "Hem", V(2.04, 0.2, 1.04), H("6E66A9"), at(0, -0.9, 0))
	sleeves(m, P, H("8E86C9"), H("38F2C0"), 1.5)
	local ra = P["Right Arm"]
	att(m, ra, "TrophyCup", V(0.5, 0.45, 0.5), H("FFB23F"), at(0, -0.9, -0.55), { mat = METAL })
	att(m, ra, "TrophyStem", V(0.14, 0.3, 0.14), H("FFB23F"), at(0, -1.25, -0.55), { mat = METAL })
	att(m, ra, "TrophyBase", V(0.4, 0.12, 0.4), H("5A3A22"), at(0, -1.42, -0.55))
	boots(m, P, H("F2F4F7"), H("8E86C9"), 0.45)
	eyes(m, Hd, H("38F2C0"), { brow = H("2A1E14"), mouthW = 0.2 })
	hairBase(m, Hd, H("5A3A22"))
	disc(m, Hd, "Cap", 0.3, 1.36, H("16181F"), at(0, 0.62, 0.02))
	att(m, Hd, "CapBill", V(1.0, 0.1, 0.6), H("16181F"), at(0, 0.5, -0.8, 5, 0, 0))
	att(m, Hd, "Headset", V(1.42, 0.1, 0.12), H("E4E7EF"), at(0, 0.62, 0.1))
	att(m, Hd, "Ear", V(0.16, 0.4, 0.4), H("38F2C0"), at(-0.7, 0.05, 0))
	rod(m, Hd, "MicArm", V(-0.7, -0.05, -0.15), V(-0.25, -0.3, -0.66), 0.05, H("E4E7EF"))
	return tag(m, "Vex", "Rank Announcer", H("38F2C0"))
end

-- Madam Coin: the Aegis Shopkeeper (elegant, fan, jewels)
npcs.Shopkeeper = function()
	local m, P = rig("Shopkeeper", { skin = H("F2C9A0"), shirt = H("6A1E5A"), pants = H("6A1E5A"), arms = H("6A1E5A") })
	local T, Hd = P.Torso, P.Head
	local gold = H("FFD700")
	att(m, T, "Front", V(0.8, 2.0, 0.05), H("FF3FA4"), at(0, 0, -0.53))
	for i = 0, 2 do att(m, T, "Gem" .. i, V(0.14, 0.14, 0.05), gold, at(0, 0.6 - i * 0.45, -0.57, 0, 0, 45), { mat = NEON }) end
	att(m, T, "Necklace", V(1.2, 0.1, 0.06), gold, at(0, 0.85, -0.54), { mat = METAL })
	att(m, T, "DressF", V(2.3, 2.0, 0.12), H("6A1E5A"), at(0, -1.95, -0.62, -7, 0, 0))
	att(m, T, "DressB", V(2.3, 2.0, 0.12), H("6A1E5A"), at(0, -1.95, 0.62, 7, 0, 0))
	att(m, T, "DressL", V(0.12, 2.0, 1.3), H("5A1A4A"), at(-1.15, -1.95, 0, 0, 0, -7))
	att(m, T, "DressR", V(0.12, 2.0, 1.3), H("5A1A4A"), at(1.15, -1.95, 0, 0, 0, 7))
	att(m, T, "DressHem", V(2.4, 0.12, 0.16), gold, at(0, -2.93, -0.74, -7, 0, 0), { mat = METAL })
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Glove", V(1.06, 0.9, 1.06), H("16181F"), at(0, -0.55, 0))
		att(m, P[a], "Bangle", V(1.12, 0.12, 1.12), gold, at(0, -0.1, 0), { mat = METAL })
	end
	-- folding fan
	local ra = P["Right Arm"]
	for i = -2, 2 do att(m, ra, "Fan" .. i, V(0.05, 0.9, 0.18), H("FF3FA4"), at(i * 0.12, -1.4, -0.45, 0, 0, i * 12)) end
	att(m, ra, "FanEdge", V(0.7, 0.08, 0.06), gold, at(0, -1.0, -0.45), { mat = METAL })
	eyes(m, Hd, H("FFD700"), { h = 0.28, lash = H("3A1E2E"), lashTilt = -14, mouthW = 0.14, mouthColor = H("C8242E") })
	att(m, Hd, "Mole", V(0.04, 0.04, 0.03), H("5A3A22"), at(0.22, -0.22, -0.6))
	hairBase(m, Hd, H("5A1A4A"), { backH = 0.8 })
	ball(m, Hd, "Updo", 0.9, H("5A1A4A"), at(0, 0.8, 0.3))
	att(m, Hd, "Pin", V(0.1, 0.6, 0.1), gold, at(0.3, 0.9, 0.3, 0, 0, -40), { mat = METAL })
	att(m, Hd, "Earring", V(0.1, 0.2, 0.1), gold, at(0.68, -0.25, 0), { mat = NEON })
	return tag(m, "Madam Coin", "Aegis Shopkeeper", H("FFD700"), H("FF3FA4"))
end

local built = {}
for id, fn in pairs(npcs) do
	local old = folder:FindFirstChild(id)
	if old then old:Destroy() end
	local m = fn()
	m.Parent = folder
	local n = 0
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	table.insert(built, id .. "(" .. n .. ")")
end
return table.concat(built, ", ")
