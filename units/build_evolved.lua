-- build_evolved.lua: evolved looks for Mythic / Secret / Aegis units (run in Studio Edit mode).
-- Clones ReplicatedStorage.UnitModels.<Id>, recolours it and adds parts -> UnitModels.<Id>_Evolved.
local RS = game:GetService("ReplicatedStorage")
local RB = require(game.ServerStorage.RigBuilder)
local V, at, A = RB.V, RB.at, RB.A
local NEON, METAL = RB.NEON, RB.METAL
local folder = RS.UnitModels

local function fresh(id)
	local old = folder:FindFirstChild(id .. "_Evolved")
	if old then old:Destroy() end
	local m = folder[id]:Clone()
	m.Name = id .. "_Evolved"
	return m
end
local function each(m, fn) for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then fn(p) end end end
local function part(m, name) return m:FindFirstChild(name, true) end
-- neon vein down the long axis of a flat part
local function vein(m, host, color)
	local s = host.Size
	local dims = { { "X", s.X }, { "Y", s.Y }, { "Z", s.Z } }
	table.sort(dims, function(a, b) return a[2] > b[2] end)
	local size = { X = s.X, Y = s.Y, Z = s.Z }
	size[dims[1][1]] = dims[1][2] * 0.86
	size[dims[2][1]] = math.max(0.06, dims[2][2] * 0.12)
	size[dims[3][1]] = dims[3][2] + 0.04
	RB.att(m, host, "Vein", V(size.X, size.Y, size.Z), color, CFrame.new(), { mat = NEON })
end
local function aura(host, color, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "EvolvedAura"
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 1
	pe.Rate = rate or 6
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Speed = NumberRange.new(1, 2.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Acceleration = Vector3.new(0, 2, 0)
	pe.Parent = host
end

------------------------------------------------------------------ Dragon -> Elder Dragon (Mythic)
do
	local m = fresh("Dragon")
	local OBSIDIAN, DEEP, GOLD, MAGMA, HAIR = Color3.fromRGB(38, 22, 32), Color3.fromRGB(64, 18, 26), Color3.fromRGB(255, 196, 70), Color3.fromRGB(255, 120, 30), Color3.fromRGB(118, 20, 34)
	each(m, function(p)
		local b = p.BrickColor.Name
		if b == "Bright red" then p.Color = OBSIDIAN
		elseif b == "Dark red" then p.Color = DEEP
		elseif b == "Med. yellowish orange" then p.Color = GOLD p.Reflectance = 0.15
		elseif b == "Khaki" or b == "Cashmere" then p.Color = GOLD p.Material = METAL
		elseif b == "Crimson" then p.Color = HAIR
		elseif b == "Neon orange" then p.Color = MAGMA p.Material = NEON
		end
		if p.Name == "Iris" then p.Color = Color3.fromRGB(255, 240, 170) end
		if p.Name:match("^Membrane") then p.Color = Color3.fromRGB(120, 30, 46) end
	end)
	local head, torso = part(m, "Head"), part(m, "Torso")
	-- gold crown of three spikes
	for i, x in ipairs({ -0.32, 0, 0.32 }) do
		RB.att(m, head, "Crown" .. i, V(0.22, i == 2 and 0.62 or 0.44, 0.22), GOLD, at(x, 0.78 + (i == 2 and 0.09 or 0), -0.18, 0, 0, x * -40), { cls = "WedgePart", mat = METAL })
	end
	RB.att(m, head, "CrownBand", V(1.38, 0.12, 1.38), GOLD, at(0, 0.6, 0.02), { mat = METAL })
	RB.att(m, head, "CrownGem", V(0.16, 0.16, 0.06), MAGMA, at(0, 0.6, -0.7, 0, 0, 45), { mat = NEON })
	-- magma veins in the wings and down the tail
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:match("^Membrane") or d.Name:match("^Tail%d")) then vein(m, d, MAGMA) end
	end
	-- flame crests on the shoulders
	for _, n in ipairs({ "Pauldron1", "Pauldron-1" }) do
		local pa = part(m, n)
		if pa then
			RB.att(m, pa, "Flame", V(0.3, 0.7, 0.5), MAGMA, CFrame.new(0, pa.Size.Y / 2 + 0.3, 0), { cls = "WedgePart", mat = NEON })
		end
	end
	-- glowing chest rune
	RB.att(m, torso, "Rune", V(0.5, 0.5, 0.05), GOLD, at(0, 0.35, -0.56, 0, 0, 45), { mat = NEON })
	aura(torso, MAGMA, 7)
	local pl = Instance.new("PointLight")
	pl.Color, pl.Brightness, pl.Range = MAGMA, 1.4, 8
	pl.Parent = torso
	m:SetAttribute("EvolvedFrom", "Dragon")
	m.Parent = folder
end

------------------------------------------------------------------ AegisChampion -> Casual Brawler (Awakened) (Aegis)
do
	local m = fresh("AegisChampion")
	local WHITE, NAVY, CYAN, ICE = Color3.fromRGB(236, 241, 250), Color3.fromRGB(24, 34, 70), Color3.fromRGB(47, 230, 255), Color3.fromRGB(150, 240, 255)
	each(m, function(p)
		local b = p.BrickColor.Name
		if b == "Smoky grey" then p.Color = WHITE
		elseif b == "Earth blue" then p.Color = NAVY
		elseif b == "Pastel blue-green" or b == "Quill grey" then p.Color = CYAN p.Material = NEON
		elseif b == "Wheat" then p.Color = CYAN p.Material = NEON
		elseif b == "White" then p.Color = NAVY
		elseif b == "Earth orange" then p.Color = ICE
		end
	end)
	-- awake: the sleepy lids open, eyes glow
	for _, n in ipairs({ "LidL", "LidR" }) do local l = part(m, n) if l then l.Transparency = 1 end end
	for _, n in ipairs({ "EyeL", "EyeR" }) do local e = part(m, n) if e then e.Color = CYAN e.Material = NEON end end
	local head, torso = part(m, "Head"), part(m, "Torso")
	-- floating halo of light shards
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2
		RB.att(m, head, "Halo" .. i, V(0.16, 0.08, 0.32), CYAN, at(math.cos(a) * 0.95, 1.05, math.sin(a) * 0.95, 0, -math.deg(a), 0), { mat = NEON })
	end
	-- Aegis emblem on the chest
	RB.att(m, torso, "Emblem", V(0.46, 0.46, 0.05), CYAN, at(0, 0.3, -0.56, 0, 0, 45), { mat = NEON })
	RB.att(m, torso, "EmblemCore", V(0.22, 0.22, 0.06), WHITE, at(0, 0.3, -0.58, 0, 0, 45), { mat = NEON })
	aura(torso, CYAN, 6)
	local pl = Instance.new("PointLight")
	pl.Color, pl.Brightness, pl.Range = CYAN, 1.2, 8
	pl.Parent = torso
	m:SetAttribute("EvolvedFrom", "AegisChampion")
	m.Parent = folder
end
print("evolved models built")
