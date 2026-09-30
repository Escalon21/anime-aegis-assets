-- RigBuilder (ModuleScript, ServerStorage): helpers to build R6-jointed characters from parts (units + lobby NPCs).
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


return { H = H, V = V, A = A, at = at, SMOOTH = SMOOTH, NEON = NEON, METAL = METAL, rig = rig, att = att, rod = rod, ball = ball, disc = disc,
	eyes = eyes, hairBase = hairBase, spikes = spikes, bangs = bangs, sleeves = sleeves, boots = boots }
