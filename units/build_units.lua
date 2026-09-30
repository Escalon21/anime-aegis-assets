-- Builds the 8 original unit models (R6 joints, parts welded to limbs) into ReplicatedStorage.UnitModels.
-- Front = -Z. Every accessory is welded to a limb, so any R6 animation (or UnitPreview's idle) moves it.
local folder = game.ReplicatedStorage.UnitModels
local H = Color3.fromHex
local V = Vector3.new
local function A(x, y, z) return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0)) end
local function at(x, y, z, rx, ry, rz) return CFrame.new(x, y, z) * A(rx, ry, rz) end
local SMOOTH, NEON, METAL = Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Metal

local R6 = {
	{ "RootJoint", "HumanoidRootPart", "Torso", CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Neck", "Torso", "Head", CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	{ "Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
}

local function newPart(cls, name, size, color, mat)
	local p = Instance.new(cls or "Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or SMOOTH
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = size.Magnitude > 1.2
	return p
end

local function rig(name, pal)
	local m = Instance.new("Model")
	m.Name = name
	local P = {}
	local function body(n, size, col)
		local p = newPart("Part", n, size, col)
		p.Parent = m
		P[n] = p
		return p
	end
	local root = body("HumanoidRootPart", V(2, 2, 1), pal.shirt)
	root.Transparency = 1
	root.Anchored = true
	root.CFrame = CFrame.new(0, 3, 0)
	m.PrimaryPart = root
	body("Torso", V(2, 2, 1), pal.shirt)
	local head = body("Head", V(2, 1, 1), pal.skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = V(1.25, 1.25, 1.25)
	mesh.Parent = head
	body("Right Arm", V(1, 2, 1), pal.arms or pal.skin)
	body("Left Arm", V(1, 2, 1), pal.arms or pal.skin)
	body("Right Leg", V(1, 2, 1), pal.pants)
	body("Left Leg", V(1, 2, 1), pal.pants)
	for _, j in ipairs(R6) do
		local mo = Instance.new("Motor6D")
		mo.Name = j[1]
		mo.Part0, mo.Part1 = P[j[2]], P[j[3]]
		mo.C0, mo.C1 = j[4], j[5]
		P[j[3]].CFrame = P[j[2]].CFrame * j[4] * j[5]:Inverse()
		mo.Parent = P[j[2]]
	end
	local ctrl = Instance.new("AnimationController")
	ctrl.Parent = m
	Instance.new("Animator").Parent = ctrl
	return m, P
end

local function att(m, host, name, size, color, cf, o)
	o = o or {}
	local p = newPart(o.cls, name, size, color, o.mat)
	if o.shape then p.Shape = o.shape end
	if o.trans then p.Transparency = o.trans end
	if o.refl then p.Reflectance = o.refl end
	p.CFrame = host.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = host, p
	w.Parent = p
	p.Parent = m
	return p
end
-- a bar from a to b (host-local); size = thickness x width x length
local function rod(m, host, name, a, b, t, color, o)
	o = o or {}
	local len = (b - a).Magnitude
	return att(m, host, name, V(t, o.w or t, len), color, CFrame.lookAt((a + b) / 2, b) * A(0, 0, o.roll or 0), o)
end
local function ball(m, host, name, d, color, cf, o)
	o = o or {}
	o.shape = Enum.PartType.Ball
	return att(m, host, name, V(d, d, d), color, cf, o)
end
-- disc/cylinder standing on its axis (axis = local Y after the rotation)
local function disc(m, host, name, h, d, color, cf, o)
	o = o or {}
	o.shape = Enum.PartType.Cylinder
	return att(m, host, name, V(h, d, d), color, cf * A(0, 0, 90), o)
end

-- anime eyes: white, iris, pupil, two shines, lash line, optional brow
local function eyes(m, head, iris, o)
	o = o or {}
	local y, h = o.y or 0.02, o.h or 0.3
	for _, s in ipairs({ -1, 1 }) do
		local x = (o.gap or 0.25) * s
		att(m, head, "EyeWhite", V(0.27, h, 0.04), H("FFFFFF"), at(x, y, -0.6))
		att(m, head, "Iris", V(0.18, h - 0.05, 0.04), iris, at(x + 0.015 * s, y - 0.02, -0.612), { mat = o.glow and NEON or SMOOTH })
		if o.slit then
			att(m, head, "Pupil", V(0.04, h - 0.08, 0.04), H("140A0A"), at(x + 0.015 * s, y - 0.02, -0.622))
		else
			att(m, head, "Pupil", V(0.08, 0.12, 0.04), H("14141C"), at(x + 0.015 * s, y - 0.03, -0.622))
		end
		att(m, head, "Shine", V(0.06, 0.06, 0.04), H("FFFFFF"), at(x - 0.03 * s, y + h * 0.22, -0.632), { mat = NEON })
		att(m, head, "Shine2", V(0.035, 0.035, 0.04), H("FFFFFF"), at(x + 0.05 * s, y - h * 0.25, -0.632), { mat = NEON })
		att(m, head, "Lash", V(0.33, 0.055, 0.05), o.lash or H("1E1820"), at(x, y + h / 2 + 0.01, -0.61, 0, 0, (o.lashTilt or -8) * s))
		if o.brow then att(m, head, "Brow", V(0.26, 0.05, 0.04), o.brow, at(x, y + h / 2 + 0.12, -0.6, 0, 0, (o.browTilt or 10) * s)) end
	end
	if o.mouth ~= false then
		att(m, head, "Mouth", V(o.mouthW or 0.16, o.mouthH or 0.04, 0.04), o.mouthColor or H("8A3C3C"), at(0, o.mouthY or -0.28, -0.6))
	end
	att(m, head, "Nose", V(0.06, 0.08, 0.03), o.nose or H("E0A888"), at(0, -0.12, -0.6))
end

-- spiky hair: cap + back + sides + wedges fanned over the crown
local function hairBase(m, head, col, o)
	o = o or {}
	att(m, head, "HairCap", V(1.32, 0.34, 1.32), col, at(0, 0.52, 0.02))
	att(m, head, "HairBack", V(1.32, o.backH or 0.85, 0.32), col, at(0, 0.5 - (o.backH or 0.85) / 2 + 0.12, 0.54))
	att(m, head, "HairSideL", V(0.2, o.sideH or 0.6, 1.1), col, at(-0.63, 0.28, 0.06))
	att(m, head, "HairSideR", V(0.2, o.sideH or 0.6, 1.1), col, at(0.63, 0.28, 0.06))
end
local function spikes(m, head, list, c1, c2)
	for i, s in ipairs(list) do
		-- { x, y, z, rx, ry, rz, sx, sy, sz }
		att(m, head, "Spike" .. i, V(s[7] or 0.35, s[8] or 0.6, s[9] or 0.3), (i % 2 == 0 and c2) or c1, at(s[1], s[2], s[3], s[4], s[5], s[6]), { cls = "WedgePart" })
	end
end
local function bangs(m, head, col, col2, n, y, len)
	n, y, len = n or 5, y or 0.42, len or 0.4
	for i = 1, n do
		local x = -0.55 + (i - 1) * (1.1 / (n - 1))
		att(m, head, "Bang" .. i, V(0.3, len, 0.18), (i % 2 == 0 and col2) or col, at(x, y, -0.56, 180, 0, (i - (n + 1) / 2) * -6), { cls = "WedgePart" })
	end
end
local function sleeves(m, P, col, cuff, len)
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Sleeve", V(1.08, len or 1.1, 1.08), col, at(0, 1 - (len or 1.1) / 2, 0))
		if cuff then att(m, P[a], "Cuff", V(1.14, 0.2, 1.14), cuff, at(0, 1 - (len or 1.1), 0)) end
	end
end
local function boots(m, P, col, sole, h)
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		att(m, P[l], "Boot", V(1.08, h or 0.7, 1.12), col, at(0, -1 + (h or 0.7) / 2, -0.04))
		att(m, P[l], "Toe", V(1.02, 0.34, 0.3), col, at(0, -0.83, -0.66))
		att(m, P[l], "Sole", V(1.1, 0.1, 1.42), sole or H("22222A"), at(0, -0.97, -0.16))
	end
end

local units = {}

------------------------------------------------------------------ Blade Initiate: young swordsman, blue gi, white headband
units.Blade = function()
	local m, P = rig("Blade", { skin = H("F2C9A0"), shirt = H("2F6FD0"), pants = H("1E2433") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Inner", V(0.6, 0.8, 0.04), H("1E2433"), at(0, 0.55, -0.515))
	att(m, T, "LapelL", V(0.26, 1.9, 0.06), H("F4F2EC"), at(-0.28, 0.05, -0.53, 0, 0, -20))
	att(m, T, "LapelR", V(0.26, 1.9, 0.06), H("F4F2EC"), at(0.28, 0.05, -0.53, 0, 0, 20))
	att(m, T, "Obi", V(2.06, 0.32, 1.06), H("1A1A22"), at(0, -0.7, 0))
	att(m, T, "ObiKnot", V(0.35, 0.3, 0.12), H("2A2A36"), at(-0.55, -0.7, -0.58, 0, 0, 20))
	att(m, T, "ObiTail", V(0.2, 0.6, 0.06), H("2A2A36"), at(-0.62, -1.05, -0.56, 0, 0, 12))
	att(m, T, "Pauldron", V(1.25, 0.34, 1.2), H("C8D2E0"), at(-1.5, 0.95, 0, 0, 0, 12), { mat = METAL })
	att(m, T, "PauldronTrim", V(1.27, 0.08, 1.22), H("3AA0FF"), at(-1.5, 0.83, 0, 0, 0, 12), { mat = NEON })
	-- sheath on the left hip
	rod(m, T, "Sheath", V(-0.95, -0.55, -0.35), V(-1.3, -1.35, 1.35), 0.22, H("16203A"))
	rod(m, T, "SheathTip", V(-1.29, -1.33, 1.3), V(-1.33, -1.42, 1.5), 0.24, H("C8D2E0"), { mat = METAL })
	sleeves(m, P, H("2F6FD0"), H("F4F2EC"), 1.15)
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do att(m, P[a], "Wrap", V(1.04, 0.3, 1.04), H("E8E2D6"), at(0, -0.4, 0)) end
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		att(m, P[l], "Hakama", V(1.14, 1.55, 1.14), H("1E2433"), at(0, 0.2, 0))
		att(m, P[l], "Pleat", V(0.06, 1.4, 0.06), H("2C3448"), at(0, 0.2, -0.58))
		att(m, P[l], "Sandal", V(0.98, 0.18, 1.25), H("3A2A1E"), at(0, -0.9, -0.12))
		att(m, P[l], "Sock", V(1.0, 0.45, 1.0), H("F4F2EC"), at(0, -0.62, 0))
	end
	-- katana held low and forward
	local arm = P["Right Arm"]
	local g = V(0, -1.1, -0.05)
	local dir = V(0, -0.55, -0.83).Unit
	rod(m, arm, "Handle", g - dir * 0.7, g, 0.15, H("22223A"))
	rod(m, arm, "Guard", g, g + dir * 0.07, 0.42, H("D8B24A"), { mat = METAL })
	rod(m, arm, "Blade", g + dir * 0.07, g + dir * 2.8, 0.06, H("E4ECF4"), { w = 0.2, mat = METAL, refl = 0.25 })
	rod(m, arm, "Edge", g + dir * 0.1, g + dir * 2.75, 0.07, H("6CC4FF"), { w = 0.04, mat = NEON })
	-- head
	eyes(m, Hd, H("2F8CFF"), { brow = H("1C2230"), browTilt = 12 })
	hairBase(m, Hd, H("1C2230"))
	att(m, Hd, "Headband", V(1.36, 0.16, 1.36), H("F4F2EC"), at(0, 0.33, 0.01))
	att(m, Hd, "Plate", V(0.5, 0.15, 0.06), H("C8D2E0"), at(0, 0.33, -0.69), { mat = METAL })
	att(m, Hd, "BandTailL", V(0.12, 0.7, 0.04), H("F4F2EC"), at(-0.12, 0.05, 0.74, 25, 0, -10))
	att(m, Hd, "BandTailR", V(0.12, 0.8, 0.04), H("F4F2EC"), at(0.14, 0.0, 0.76, 30, 0, 12))
	spikes(m, Hd, {
		{ -0.45, 0.85, 0.1, -20, 0, 30, 0.4, 0.7, 0.4 }, { 0, 0.95, 0.05, -25, 0, 0, 0.45, 0.8, 0.45 }, { 0.45, 0.85, 0.1, -20, 0, -30, 0.4, 0.7, 0.4 },
		{ -0.3, 0.8, 0.45, 30, 0, 20, 0.4, 0.7, 0.35 }, { 0.3, 0.8, 0.45, 30, 0, -20, 0.4, 0.7, 0.35 }, { 0, 0.75, 0.6, 50, 0, 0, 0.5, 0.8, 0.35 },
		{ -0.7, 0.55, 0.2, 0, 0, 55, 0.3, 0.55, 0.4 }, { 0.7, 0.55, 0.2, 0, 0, -55, 0.3, 0.55, 0.4 },
	}, H("1C2230"), H("2E3F66"))
	bangs(m, Hd, H("1C2230"), H("2E3F66"), 5, 0.4, 0.42)
	return m
end

------------------------------------------------------------------ Spirit Gunner: gunslinger, amber coat, wide hat, twin spirit pistols
units.Gunner = function()
	local m, P = rig("Gunner", { skin = H("E8B48E"), shirt = H("C8862E"), pants = H("3B3F52"), arms = H("C8862E") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Shirt", V(0.8, 1.8, 0.04), H("F3E6C8"), at(0, 0.05, -0.53))
	att(m, T, "Button1", V(0.1, 0.1, 0.04), H("8A5A2A"), at(0, 0.5, -0.555))
	att(m, T, "Button2", V(0.1, 0.1, 0.04), H("8A5A2A"), at(0, 0.1, -0.555))
	att(m, T, "Scarf", V(1.4, 0.32, 1.22), H("C8342E"), at(0, 0.92, 0))
	att(m, T, "ScarfKnot", V(0.4, 0.4, 0.2), H("A82A26"), at(0.2, 0.7, -0.6, 0, 0, 25))
	att(m, T, "ScarfTail", V(0.3, 0.8, 0.08), H("C8342E"), at(0.3, 0.3, -0.62, 0, 0, 12))
	att(m, T, "Belt", V(2.1, 0.24, 1.1), H("5A3A22"), at(0, -0.78, 0))
	att(m, T, "Buckle", V(0.36, 0.26, 0.06), H("E8C35A"), at(0, -0.78, -0.58), { mat = METAL })
	rod(m, T, "Bandolier", V(0.85, 0.95, -0.57), V(-0.85, -0.6, -0.57), 0.08, H("5A3A22"), { w = 0.22 })
	for i = 0, 4 do
		local p = V(0.6, 0.7, -0.62):Lerp(V(-0.55, -0.35, -0.62), i / 4)
		att(m, T, "Bullet" .. i, V(0.08, 0.16, 0.06), H("E8C35A"), CFrame.new(p) * A(0, 0, 42), { mat = METAL })
	end
	att(m, T, "CoatTail", V(2.0, 1.35, 0.12), H("B87628"), at(0, -1.6, 0.5, 8, 0, 0))
	att(m, T, "CollarL", V(0.5, 0.5, 0.12), H("A86A22"), at(-0.55, 0.85, -0.55, 0, 0, -25))
	att(m, T, "CollarR", V(0.5, 0.5, 0.12), H("A86A22"), at(0.55, 0.85, -0.55, 0, 0, 25))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Cuff", V(1.14, 0.22, 1.14), H("A86A22"), at(0, -0.45, 0))
		att(m, P[a], "Glove", V(1.06, 0.45, 1.06), H("5A3A22"), at(0, -0.78, 0))
		-- spirit pistol, pointing forward
		local g = V(0, -1.05, -0.2)
		att(m, P[a], "Grip", V(0.24, 0.45, 0.28), H("3A2A1E"), CFrame.new(g) * A(-15, 0, 0))
		att(m, P[a], "Frame", V(0.26, 0.3, 0.9), H("3A3D48"), CFrame.new(g + V(0, -0.02, -0.45)), { mat = METAL })
		rod(m, P[a], "Barrel", g + V(0, 0.05, -0.85), g + V(0, 0.05, -1.3), 0.14, H("2A2C34"), { mat = METAL })
		att(m, P[a], "Core", V(0.28, 0.14, 0.4), H("FFB23F"), CFrame.new(g + V(0, 0.14, -0.4)), { mat = NEON })
	end
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do att(m, P[l], "Chap", V(1.04, 1.1, 0.06), H("5A3A22"), at(0, 0.3, -0.53)) end
	boots(m, P, H("5A3A22"), H("2A1E14"), 0.9)
	att(m, P["Right Leg"], "Holster", V(0.3, 0.7, 0.5), H("5A3A22"), at(0.55, 0.45, 0))
	-- head
	eyes(m, Hd, H("FFB23F"), { brow = H("B8741E"), browTilt = 6, mouthW = 0.2 })
	att(m, Hd, "Smirk", V(0.08, 0.04, 0.04), H("8A3C3C"), at(0.11, -0.26, -0.6, 0, 0, 25))
	hairBase(m, Hd, H("E0A040"), { backH = 0.7 })
	spikes(m, Hd, { { -0.66, 0.2, -0.1, 0, 0, 40, 0.25, 0.5, 0.4 }, { 0.66, 0.2, -0.1, 0, 0, -40, 0.25, 0.5, 0.4 }, { 0, 0.05, 0.62, 60, 0, 0, 0.6, 0.6, 0.3 } }, H("E0A040"), H("C88A30"))
	bangs(m, Hd, H("E0A040"), H("C88A30"), 4, 0.38, 0.34)
	disc(m, Hd, "Brim", 0.1, 2.5, H("8A5A2A"), at(0, 0.62, 0.05, 6, 0, 0))
	disc(m, Hd, "Crown", 0.62, 1.4, H("8A5A2A"), at(0, 0.95, 0.08, 6, 0, 0))
	disc(m, Hd, "Band", 0.14, 1.44, H("FFB23F"), at(0, 0.72, 0.07, 6, 0, 0), { mat = NEON })
	disc(m, Hd, "GoggleL", 0.14, 0.34, H("7FE8FF"), at(-0.22, 0.95, -0.66, 96, 0, 0), { mat = NEON })
	disc(m, Hd, "GoggleR", 0.14, 0.34, H("7FE8FF"), at(0.22, 0.95, -0.66, 96, 0, 0), { mat = NEON })
	return m
end

------------------------------------------------------------------ Storm Caller: robed storm mage, white hair, staff with a lightning orb
units.Mage = function()
	local m, P = rig("Mage", { skin = H("F5D6C0"), shirt = H("5B2D8E"), pants = H("3F1F66"), arms = H("5B2D8E") })
	local T, Hd = P.Torso, P.Head
	local gold = H("E8C35A")
	att(m, T, "TrimL", V(0.12, 2.0, 0.05), gold, at(-0.3, 0, -0.52), { mat = METAL })
	att(m, T, "TrimR", V(0.12, 2.0, 0.05), gold, at(0.3, 0, -0.52), { mat = METAL })
	att(m, T, "Sash", V(2.08, 0.3, 1.08), H("3F1F66"), at(0, -0.6, 0))
	att(m, T, "Gem", V(0.26, 0.26, 0.08), H("7FE8FF"), at(0, -0.6, -0.56, 0, 0, 45), { mat = NEON })
	att(m, T, "Collar", V(1.6, 0.45, 1.2), H("4A2478"), at(0, 1.05, 0.05))
	att(m, T, "Hood", V(1.5, 0.8, 0.55), H("4A2478"), at(0, 1.0, 0.55, -20, 0, 0))
	-- robe skirt (on the torso so the legs move beneath it)
	att(m, T, "RobeF", V(2.1, 1.9, 0.12), H("5B2D8E"), at(0, -1.9, -0.6, -6, 0, 0))
	att(m, T, "RobeB", V(2.1, 1.9, 0.12), H("5B2D8E"), at(0, -1.9, 0.6, 6, 0, 0))
	att(m, T, "RobeL", V(0.12, 1.9, 1.2), H("4A2478"), at(-1.08, -1.9, 0, 0, 0, -6))
	att(m, T, "RobeR", V(0.12, 1.9, 1.2), H("4A2478"), at(1.08, -1.9, 0, 0, 0, 6))
	att(m, T, "HemF", V(2.2, 0.12, 0.16), gold, at(0, -2.83, -0.7, -6, 0, 0), { mat = METAL })
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Bell", V(1.34, 0.6, 1.34), H("4A2478"), at(0, -0.55, 0))
		att(m, P[a], "BellTrim", V(1.38, 0.1, 1.38), gold, at(0, -0.86, 0), { mat = METAL })
		att(m, P[a], "Hand", V(0.8, 0.35, 0.8), H("F5D6C0"), at(0, -1.0, 0))
	end
	-- staff through the right hand, orb + prongs + sparks
	local arm = P["Right Arm"]
	rod(m, arm, "Staff", V(0, -3.0, -0.25), V(0, 1.7, -0.25), 0.16, H("3A2A4A"))
	ball(m, arm, "Orb", 0.7, H("7FE8FF"), at(0, 2.05, -0.25), { mat = NEON })
	for i = 0, 2 do
		local ang = math.rad(i * 120)
		rod(m, arm, "Prong" .. i, V(0, 1.6, -0.25), V(math.cos(ang) * 0.45, 2.35, -0.25 + math.sin(ang) * 0.45), 0.08, gold, { mat = METAL })
	end
	att(m, arm, "SparkA", V(0.06, 0.5, 0.06), H("CFF6FF"), at(0.5, 2.4, -0.25, 0, 0, 30), { mat = NEON })
	att(m, arm, "SparkB", V(0.06, 0.4, 0.06), H("CFF6FF"), at(-0.45, 2.5, -0.1, 0, 0, -40), { mat = NEON })
	-- head
	eyes(m, Hd, H("8EE8FF"), { glow = true, brow = H("D8D4F0"), browTilt = 4 })
	hairBase(m, Hd, H("E8E4FF"), { backH = 1.9, sideH = 0.9 })
	att(m, Hd, "LockL", V(0.26, 1.4, 0.36), H("E8E4FF"), at(-0.6, -0.35, -0.3))
	att(m, Hd, "LockR", V(0.26, 1.4, 0.36), H("E8E4FF"), at(0.6, -0.35, -0.3))
	spikes(m, Hd, { { -0.35, 0.78, 0.15, -10, 0, 25, 0.4, 0.45, 0.45 }, { 0.35, 0.78, 0.15, -10, 0, -25, 0.4, 0.45, 0.45 }, { 0, 0.8, 0.35, 20, 0, 0, 0.5, 0.45, 0.4 } }, H("E8E4FF"), H("C8C0F0"))
	bangs(m, Hd, H("E8E4FF"), H("C8C0F0"), 5, 0.42, 0.46)
	att(m, Hd, "Circlet", V(1.38, 0.1, 1.38), gold, at(0, 0.36, 0.01), { mat = METAL })
	att(m, Hd, "CircletGem", V(0.18, 0.18, 0.06), H("BE6EFF"), at(0, 0.38, -0.7, 0, 0, 45), { mat = NEON })
	return m
end

------------------------------------------------------------------ Ninja: hooded, masked, red scarf, shuriken
units.Ninja = function()
	local m, P = rig("Ninja", { skin = H("E8C4A0"), shirt = H("23232E"), pants = H("23232E"), arms = H("23232E") })
	local T, Hd = P.Torso, P.Head
	att(m, T, "Vest", V(1.7, 1.3, 0.08), H("3A3A4A"), at(0, 0.3, -0.53))
	att(m, T, "VestLine", V(0.06, 1.3, 0.04), H("55556A"), at(0, 0.3, -0.58))
	att(m, T, "Belt", V(2.06, 0.26, 1.06), H("4A4A5C"), at(0, -0.72, 0))
	att(m, T, "Pouch1", V(0.4, 0.34, 0.25), H("2E2E3C"), at(-0.6, -0.9, -0.6))
	att(m, T, "Pouch2", V(0.4, 0.34, 0.25), H("2E2E3C"), at(0.6, -0.9, -0.6))
	att(m, T, "Scarf", V(1.4, 0.36, 1.26), H("C8242E"), at(0, 0.92, 0))
	rod(m, T, "ScarfTail1", V(0.35, 0.9, 0.62), V(1.1, 0.2, 1.3), 0.08, H("C8242E"), { w = 0.38 })
	rod(m, T, "ScarfTail2", V(1.05, 0.25, 1.25), V(1.7, -0.45, 1.75), 0.08, H("A81E26"), { w = 0.32 })
	rod(m, T, "ScarfTail3", V(0.1, 0.9, 0.62), V(0.6, 0.0, 1.45), 0.08, H("A81E26"), { w = 0.3 })
	rod(m, T, "Tanto", V(-0.2, 0.75, 0.6), V(0.9, -0.75, 0.65), 0.16, H("2A2A36"))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		for i = 0, 2 do att(m, P[a], "Wrap" .. i, V(1.05, 0.12, 1.05), H("B8B8C4"), at(0, -0.3 - i * 0.2, 0, 0, 0, (i % 2 == 0) and 6 or -6)) end
		att(m, P[a], "Guard", V(0.5, 0.6, 0.12), H("55556A"), at(0, -0.4, -0.55), { mat = METAL })
	end
	-- shuriken in the right hand
	local arm = P["Right Arm"]
	for i = 0, 1 do att(m, arm, "Star" .. i, V(0.9, 0.12, 0.05), H("C8D0DC"), at(0, -1.2, -0.35, 0, 0, 45 + i * 90), { mat = METAL, refl = 0.2 }) end
	disc(m, arm, "StarHub", 0.07, 0.22, H("2A2A36"), at(0, -1.2, -0.37, 90, 0, 0))
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		for i = 0, 2 do att(m, P[l], "LegWrap" .. i, V(1.05, 0.12, 1.05), H("B8B8C4"), at(0, -0.3 - i * 0.18, 0)) end
		att(m, P[l], "Tabi", V(1.04, 0.3, 1.2), H("15151E"), at(0, -0.86, -0.1))
	end
	-- head: hood + mask, only the eyes show
	eyes(m, Hd, H("E8413A"), { h = 0.2, y = 0.06, brow = H("15151E"), browTilt = 16, mouth = false })
	att(m, Hd, "Mask", V(1.34, 0.46, 0.12), H("2E2E3C"), at(0, -0.24, -0.6))
	att(m, Hd, "HoodCap", V(1.4, 0.5, 1.4), H("23232E"), at(0, 0.5, 0.02))
	att(m, Hd, "HoodBack", V(1.4, 1.1, 0.36), H("23232E"), at(0, 0.02, 0.56))
	att(m, Hd, "HoodL", V(0.2, 1.05, 1.2), H("23232E"), at(-0.66, 0.05, 0.02))
	att(m, Hd, "HoodR", V(0.2, 1.05, 1.2), H("23232E"), at(0.66, 0.05, 0.02))
	att(m, Hd, "HoodPeak", V(1.3, 0.2, 0.3), H("23232E"), at(0, 0.5, -0.62, -20, 0, 0), { cls = "WedgePart" })
	att(m, Hd, "Forehead", V(0.7, 0.2, 0.06), H("C8D0DC"), at(0, 0.33, -0.69), { mat = METAL })
	att(m, Hd, "Mark", V(0.2, 0.08, 0.04), H("E8413A"), at(0, 0.33, -0.725), { mat = NEON })
	return m
end

------------------------------------------------------------------ Dragon: dragon warrior, scale armour, horns, wings, tail
units.Dragon = function()
	local m, P = rig("Dragon", { skin = H("F0C0A0"), shirt = H("8E1A1A"), pants = H("3A1010"), arms = H("8E1A1A") })
	local T, Hd = P.Torso, P.Head
	local scale, dark, gold, ember = H("B32222"), H("5A0E0E"), H("E8B04A"), H("FF7A2E")
	for row = 0, 2 do
		for col = -1, 1 do
			att(m, T, "Scale" .. row .. col, V(0.62, 0.42, 0.1), (row + col) % 2 == 0 and scale or H("A01C1C"), at(col * 0.6, 0.65 - row * 0.45, -0.54, -8, 0, 0))
		end
	end
	att(m, T, "Core", V(0.3, 0.3, 0.08), ember, at(0, 0.2, -0.62, 0, 0, 45), { mat = NEON })
	att(m, T, "Belt", V(2.08, 0.28, 1.08), dark, at(0, -0.75, 0))
	att(m, T, "Buckle", V(0.4, 0.3, 0.08), gold, at(0, -0.75, -0.58, 0, 0, 45), { mat = METAL })
	att(m, T, "Fauld", V(2.0, 0.6, 0.12), scale, at(0, -1.2, -0.56, -8, 0, 0))
	for _, s in ipairs({ -1, 1 }) do
		-- wings: bone + two membranes
		local base, tip = V(0.45 * s, 0.7, 0.55), V(2.6 * s, 2.2, 1.3)
		rod(m, T, "WingBone", base, tip, 0.18, dark)
		rod(m, T, "WingBone2", tip, V(3.1 * s, 0.4, 1.5), 0.12, dark)
		rod(m, T, "Membrane1", V(0.5 * s, 0.2, 0.62), V(2.5 * s, 1.4, 1.3), 0.05, H("C82828"), { w = 1.4, roll = 90 })
		rod(m, T, "Membrane2", V(1.6 * s, 0.4, 1.0), V(3.0 * s, 0.8, 1.45), 0.05, H("A82020"), { w = 1.2, roll = 90 })
		att(m, T, "Claw" .. s, V(0.14, 0.4, 0.14), H("E8DCC0"), CFrame.new(tip + V(0, 0.2, 0)), { cls = "WedgePart" })
		-- pauldron spikes
		att(m, T, "Pauldron" .. s, V(1.3, 0.4, 1.2), scale, at(1.5 * s, 0.95, 0, 0, 0, -10 * s))
		att(m, T, "Spike" .. s, V(0.25, 0.6, 0.35), H("E8DCC0"), at(1.7 * s, 1.35, 0, 0, 0, -25 * s), { cls = "WedgePart" })
	end
	-- tail
	local pts = { V(0, -0.8, 0.5), V(0, -1.4, 1.4), V(0.4, -2.2, 2.1), V(1.0, -2.7, 2.5), V(1.7, -2.8, 2.6) }
	for i = 1, #pts - 1 do rod(m, T, "Tail" .. i, pts[i], pts[i + 1], 0.5 - i * 0.08, i % 2 == 0 and scale or H("A01C1C")) end
	att(m, T, "TailTip", V(0.1, 0.5, 0.6), ember, CFrame.lookAt(pts[5], pts[5] + V(1, 0, 0)), { mat = NEON, cls = "WedgePart" })
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Vambrace", V(1.1, 0.8, 1.1), scale, at(0, -0.4, 0))
		att(m, P[a], "Trim", V(1.14, 0.08, 1.14), gold, at(0, -0.02, 0), { mat = METAL })
		att(m, P[a], "Hand", V(1.0, 0.35, 1.0), H("F0C0A0"), at(0, -0.95, 0))
		for i = -1, 1 do att(m, P[a], "Talon" .. i, V(0.12, 0.3, 0.12), H("2A0A0A"), at(i * 0.3, -1.2, -0.35, 20, 0, 0), { cls = "WedgePart" }) end
	end
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		att(m, P[l], "Greave", V(1.1, 0.9, 1.1), scale, at(0, -0.4, 0))
		att(m, P[l], "Knee", V(0.6, 0.4, 0.2), gold, at(0, 0.1, -0.56, 0, 0, 45), { mat = METAL })
	end
	boots(m, P, dark, H("1A0606"), 0.5)
	-- head
	eyes(m, Hd, H("FFB23F"), { glow = true, slit = true, brow = H("5A0E0E"), browTilt = 18 })
	att(m, Hd, "Fang", V(0.05, 0.08, 0.03), H("FFFFFF"), at(0.06, -0.31, -0.605))
	hairBase(m, Hd, H("9E1818"), { backH = 1.0 })
	spikes(m, Hd, {
		{ -0.45, 0.85, 0.15, -30, 0, 35, 0.4, 0.8, 0.4 }, { 0, 1.0, 0.1, -35, 0, 0, 0.45, 0.95, 0.45 }, { 0.45, 0.85, 0.15, -30, 0, -35, 0.4, 0.8, 0.4 },
		{ -0.3, 0.75, 0.55, 40, 0, 25, 0.4, 0.8, 0.35 }, { 0.3, 0.75, 0.55, 40, 0, -25, 0.4, 0.8, 0.35 }, { 0, 0.6, 0.7, 65, 0, 0, 0.5, 0.9, 0.35 },
	}, H("9E1818"), ember)
	bangs(m, Hd, H("9E1818"), H("C82828"), 5, 0.42, 0.44)
	for _, s in ipairs({ -1, 1 }) do
		rod(m, Hd, "Horn" .. s, V(0.4 * s, 0.55, -0.05), V(0.7 * s, 1.1, 0.3), 0.2, H("E8DCC0"))
		rod(m, Hd, "HornTip" .. s, V(0.7 * s, 1.1, 0.3), V(0.62 * s, 1.45, 0.75), 0.13, H("C8B898"))
	end
	return m
end

------------------------------------------------------------------ Aegis Warden: heavy knight, glowing visor, tower shield, lance, cape
units.AegisWarden = function()
	local m, P = rig("AegisWarden", { skin = H("D9B08C"), shirt = H("2A3240"), pants = H("2A3240"), arms = H("2A3240") })
	local T, Hd = P.Torso, P.Head
	local steel, trim, teal, cape = H("C8D0DC"), H("8E9AAA"), H("00FFC8"), H("106B5F")
	att(m, T, "Breastplate", V(2.14, 1.35, 1.14), steel, at(0, 0.35, 0), { mat = METAL })
	att(m, T, "Emblem", V(0.5, 0.6, 0.08), teal, at(0, 0.35, -0.6), { mat = NEON })
	att(m, T, "EmblemRim", V(0.66, 0.76, 0.06), trim, at(0, 0.35, -0.585), { mat = METAL })
	for i = 0, 1 do att(m, T, "Ab" .. i, V(1.6, 0.26, 1.1), i == 0 and trim or steel, at(0, -0.45 - i * 0.28, 0), { mat = METAL }) end
	att(m, T, "Tabard", V(0.8, 1.5, 0.08), cape, at(0, -1.25, -0.57))
	att(m, T, "TabardLine", V(0.08, 1.4, 0.04), teal, at(0, -1.25, -0.62), { mat = NEON })
	att(m, T, "Cape", V(2.0, 3.4, 0.12), cape, at(0, -0.65, 0.64, 7, 0, 0))
	att(m, T, "CapeTrim", V(2.02, 0.12, 0.14), teal, at(0, -2.33, 0.85, 7, 0, 0), { mat = NEON })
	for _, s in ipairs({ -1, 1 }) do
		att(m, T, "Pauldron" .. s, V(1.55, 0.62, 1.45), steel, at(1.5 * s, 0.95, 0, 0, 0, -12 * s), { mat = METAL })
		att(m, T, "PauldronTrim" .. s, V(1.58, 0.1, 1.48), teal, at(1.52 * s, 0.68, 0, 0, 0, -12 * s), { mat = NEON })
	end
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		att(m, P[a], "Gauntlet", V(1.14, 0.9, 1.14), steel, at(0, -0.5, 0), { mat = METAL })
		att(m, P[a], "Knuckle", V(1.16, 0.2, 1.16), trim, at(0, -0.9, 0), { mat = METAL })
	end
	-- tower shield on the left arm, facing forward
	local la = P["Left Arm"]
	att(m, la, "Shield", V(1.9, 2.6, 0.22), steel, at(-0.1, -0.5, -0.85), { mat = METAL })
	att(m, la, "ShieldRim", V(2.05, 2.75, 0.16), trim, at(-0.1, -0.5, -0.8), { mat = METAL })
	att(m, la, "ShieldCore", V(0.6, 0.9, 0.06), teal, at(-0.1, -0.35, -0.98), { mat = NEON })
	att(m, la, "ShieldBar", V(0.12, 2.2, 0.05), teal, at(-0.1, -0.5, -0.975), { mat = NEON })
	-- lance in the right hand
	local ra = P["Right Arm"]
	rod(m, ra, "Lance", V(0, -2.9, -0.25), V(0, 2.2, -0.25), 0.18, H("3A4454"), { mat = METAL })
	att(m, ra, "LanceTip", V(0.3, 0.9, 0.3), teal, at(0, 2.6, -0.25), { mat = NEON, cls = "WedgePart" })
	disc(m, ra, "LanceGuard", 0.12, 0.5, trim, at(0, 1.95, -0.25), { mat = METAL })
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		att(m, P[l], "Greave", V(1.1, 1.1, 1.12), steel, at(0, -0.3, -0.02), { mat = METAL })
		att(m, P[l], "Knee", V(0.7, 0.45, 0.24), trim, at(0, 0.3, -0.56), { mat = METAL })
	end
	boots(m, P, trim, H("1A2028"), 0.5)
	-- full helmet
	att(m, Hd, "Helm", V(1.38, 1.25, 1.38), steel, at(0, 0.12, 0), { mat = METAL })
	att(m, Hd, "Visor", V(1.4, 0.3, 0.12), H("1A2028"), at(0, 0.05, -0.68))
	att(m, Hd, "Slit", V(1.05, 0.07, 0.05), teal, at(0, 0.05, -0.75), { mat = NEON })
	att(m, Hd, "Crest", V(0.14, 0.55, 1.3), teal, at(0, 0.95, 0.05), { mat = NEON })
	att(m, Hd, "CrestBase", V(0.3, 0.2, 1.36), trim, at(0, 0.76, 0.05), { mat = METAL })
	att(m, Hd, "CheekL", V(0.14, 0.6, 0.6), trim, at(-0.7, -0.2, -0.3), { mat = METAL })
	att(m, Hd, "CheekR", V(0.14, 0.6, 0.6), trim, at(0.7, -0.2, -0.3), { mat = METAL })
	return m
end

------------------------------------------------------------------ Pop Idol: twin tails, headset, frilly stage outfit, microphone
units.Idol = function()
	local m, P = rig("Idol", { skin = H("F8D8C8"), shirt = H("F4F2FA"), pants = H("F8D8C8") })
	local T, Hd = P.Torso, P.Head
	local pink, hot, hair, star = H("FF8AC8"), H("FF3FA4"), H("FFA8D8"), H("FFE14D")
	att(m, T, "Collar", V(1.6, 0.5, 1.15), H("B9B3EC"), at(0, 0.8, 0.02))
	att(m, T, "BowL", V(0.45, 0.35, 0.1), hot, at(-0.25, 0.55, -0.6, 0, 0, 20), { cls = "WedgePart" })
	att(m, T, "BowR", V(0.45, 0.35, 0.1), hot, at(0.25, 0.55, -0.6, 0, 0, -20), { cls = "WedgePart" })
	att(m, T, "BowKnot", V(0.18, 0.18, 0.12), star, at(0, 0.55, -0.63), { mat = NEON })
	att(m, T, "Waist", V(2.06, 0.26, 1.06), hot, at(0, -0.6, 0))
	-- flared skirt with a white frill
	att(m, T, "SkirtF", V(2.3, 0.85, 0.12), pink, at(0, -1.1, -0.66, -22, 0, 0))
	att(m, T, "SkirtB", V(2.3, 0.85, 0.12), pink, at(0, -1.1, 0.66, 22, 0, 0))
	att(m, T, "SkirtL", V(0.12, 0.85, 1.4), pink, at(-1.16, -1.1, 0, 0, 0, -22))
	att(m, T, "SkirtR", V(0.12, 0.85, 1.4), pink, at(1.16, -1.1, 0, 0, 0, 22))
	att(m, T, "FrillF", V(2.5, 0.14, 0.14), H("FFFFFF"), at(0, -1.5, -0.84, -22, 0, 0))
	att(m, T, "FrillB", V(2.5, 0.14, 0.14), H("FFFFFF"), at(0, -1.5, 0.84, 22, 0, 0))
	for _, a in ipairs({ "Right Arm", "Left Arm" }) do
		ball(m, P[a], "Puff", 1.35, H("F4F2FA"), at(0, 0.6, 0))
		att(m, P[a], "PuffBand", V(1.12, 0.14, 1.12), hot, at(0, 0.1, 0))
		att(m, P[a], "Glove", V(1.06, 0.8, 1.06), H("FFFFFF"), at(0, -0.6, 0))
	end
	-- microphone
	local ra = P["Right Arm"]
	rod(m, ra, "MicHandle", V(0, -1.0, -0.15), V(0, -0.55, -0.75), 0.16, hot)
	ball(m, ra, "MicHead", 0.34, H("E8ECF4"), CFrame.new(0, -0.45, -0.85), { mat = METAL })
	att(m, P["Left Arm"], "Heart", V(0.3, 0.3, 0.08), hot, at(0, -1.3, -0.4, 0, 0, 45), { mat = NEON })
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do
		att(m, P[l], "Boot", V(1.1, 1.0, 1.12), H("FFFFFF"), at(0, -0.5, -0.02))
		att(m, P[l], "BootTop", V(1.16, 0.16, 1.16), hot, at(0, 0.0, -0.02))
		att(m, P[l], "Sole", V(1.12, 0.12, 1.3), hot, at(0, -0.96, -0.1))
	end
	-- head
	eyes(m, Hd, H("FF3FA4"), { h = 0.34, lash = H("5A1E3C"), lashTilt = -12, mouthW = 0.12, mouthH = 0.07, mouthColor = H("E85C8A") })
	att(m, Hd, "BlushL", V(0.2, 0.06, 0.03), H("FF9EB8"), at(-0.38, -0.16, -0.6))
	att(m, Hd, "BlushR", V(0.2, 0.06, 0.03), H("FF9EB8"), at(0.38, -0.16, -0.6))
	hairBase(m, Hd, hair, { backH = 1.1, sideH = 0.9 })
	bangs(m, Hd, hair, H("FF8AC8"), 6, 0.42, 0.36)
	for _, s in ipairs({ -1, 1 }) do
		ball(m, Hd, "Scrunchie" .. s, 0.34, star, at(0.72 * s, 0.55, 0.15), { mat = NEON })
		rod(m, Hd, "TailA" .. s, V(0.78 * s, 0.5, 0.2), V(1.15 * s, -0.5, 0.35), 0.45, hair)
		rod(m, Hd, "TailB" .. s, V(1.15 * s, -0.5, 0.35), V(1.05 * s, -1.6, 0.45), 0.38, H("FF8AC8"))
		rod(m, Hd, "TailC" .. s, V(1.05 * s, -1.6, 0.45), V(0.85 * s, -2.2, 0.4), 0.26, hair)
	end
	-- headset
	att(m, Hd, "Headband", V(1.42, 0.08, 0.1), H("E8ECF4"), at(0, 0.62, 0.0))
	att(m, Hd, "EarPiece", V(0.14, 0.36, 0.36), hot, at(0.7, 0.1, 0))
	rod(m, Hd, "MicArm", V(0.7, 0.0, -0.15), V(0.25, -0.28, -0.65), 0.04, H("E8ECF4"))
	att(m, Hd, "StarClip", V(0.25, 0.25, 0.06), star, at(-0.45, 0.55, -0.62, 0, 0, 45), { mat = NEON })
	return m
end

------------------------------------------------------------------ Merchant: travelling trader, straw hat, glasses, big pack, lucky coin
units.Merchant = function()
	local m, P = rig("Merchant", { skin = H("EBC29A"), shirt = H("F2EBDD"), pants = H("5A4632") })
	local T, Hd = P.Torso, P.Head
	local vest, gold, strap = H("2E6B4A"), H("FFD700"), H("6A4A2A")
	att(m, T, "VestL", V(0.72, 1.9, 1.06), vest, at(-0.66, 0.02, 0))
	att(m, T, "VestR", V(0.72, 1.9, 1.06), vest, at(0.66, 0.02, 0))
	att(m, T, "VestBack", V(2.06, 1.9, 0.1), vest, at(0, 0.02, 0.52))
	att(m, T, "BowTie", V(0.4, 0.2, 0.08), gold, at(0, 0.82, -0.54), { mat = METAL })
	att(m, T, "Belt", V(2.08, 0.24, 1.08), strap, at(0, -0.78, 0))
	att(m, T, "Purse", V(0.5, 0.5, 0.35), H("8A5A2A"), at(0.62, -1.0, -0.55))
	disc(m, T, "PurseCoin", 0.06, 0.26, gold, at(0.62, -1.0, -0.74, 90, 0, 0), { mat = NEON })
	-- big pack
	att(m, T, "Pack", V(1.7, 1.9, 0.95), H("8A5A2A"), at(0, 0.2, 1.0))
	att(m, T, "PackFlap", V(1.74, 0.5, 1.0), H("6A4A2A"), at(0, 1.0, 1.0))
	disc(m, T, "Scroll", 1.6, 0.36, H("E8DCC0"), at(0, 1.4, 0.95, 0, 0, 90))
	att(m, T, "Bundle", V(0.6, 0.5, 0.5), H("C8342E"), at(0.5, 1.45, 1.3, 0, 20, 0))
	for _, s in ipairs({ -1, 1 }) do att(m, T, "Strap" .. s, V(0.18, 2.0, 0.06), strap, at(0.55 * s, 0.1, -0.54)) end
	sleeves(m, P, H("F2EBDD"), vest, 1.2)
	-- lucky coin in the right hand
	disc(m, P["Right Arm"], "Coin", 0.08, 0.6, gold, at(0, -1.25, -0.3, 90, 0, 0), { mat = NEON })
	att(m, P["Left Arm"], "Ledger", V(0.2, 0.7, 0.55), H("2E6B4A"), at(0, -1.15, -0.2))
	for _, l in ipairs({ "Right Leg", "Left Leg" }) do att(m, P[l], "Cuff", V(1.08, 0.2, 1.08), H("4A3826"), at(0, -0.55, 0)) end
	boots(m, P, H("4A3826"), H("22180E"), 0.45)
	-- head: happy closed eyes behind round glasses
	for _, s in ipairs({ -1, 1 }) do
		att(m, Hd, "EyeArcA", V(0.16, 0.05, 0.04), H("2A1E14"), at(0.25 * s - 0.06, 0.04, -0.6, 0, 0, 30))
		att(m, Hd, "EyeArcB", V(0.16, 0.05, 0.04), H("2A1E14"), at(0.25 * s + 0.06, 0.04, -0.6, 0, 0, -30))
		disc(m, Hd, "Lens" .. s, 0.03, 0.4, H("BFE8FF"), at(0.25 * s, 0.02, -0.64, 90, 0, 0), { trans = 0.6 })
		disc(m, Hd, "Rim" .. s, 0.02, 0.44, H("2A1E14"), at(0.25 * s, 0.02, -0.63, 90, 0, 0))
	end
	att(m, Hd, "Bridge", V(0.1, 0.04, 0.04), H("2A1E14"), at(0, 0.06, -0.64))
	att(m, Hd, "Smile", V(0.26, 0.05, 0.04), H("8A3C3C"), at(0, -0.26, -0.6))
	att(m, Hd, "Nose", V(0.08, 0.1, 0.04), H("D8A880"), at(0, -0.1, -0.6))
	hairBase(m, Hd, H("6A4A2A"), { backH = 0.6 })
	att(m, Hd, "Mustache", V(0.44, 0.08, 0.05), H("6A4A2A"), at(0, -0.19, -0.61))
	disc(m, Hd, "HatBrim", 0.1, 2.6, H("D9B96A"), at(0, 0.62, 0))
	att(m, Hd, "HatCone", V(1.3, 0.7, 1.3), H("D9B96A"), at(0, 0.95, 0), { cls = "WedgePart" })
	att(m, Hd, "HatCone2", V(1.3, 0.7, 1.3), H("CCAA5C"), at(0, 0.95, 0, 0, 180, 0), { cls = "WedgePart" })
	disc(m, Hd, "HatBand", 0.14, 1.34, H("C8342E"), at(0, 0.7, 0))
	return m
end

local built = {}
for id, fn in pairs(units) do
	local old = folder:FindFirstChild(id)
	if old then old:Destroy() end
	local m = fn()
	local n = 0
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	m.Parent = folder
	table.insert(built, id .. "(" .. n .. ")")
end
return table.concat(built, ", ")
