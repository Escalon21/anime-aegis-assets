-- SummonHallService (Script) -> ServerScriptService
-- Brings the Blender-made Summon Hall to life. Works wherever you place the imported model:
-- it finds any Model that contains an "MK_Summoner" part (the name contract from summon_hall.py).
--   * colours / materials from the "__style" suffix of every mesh name
--   * collisions only on Wall_/Floor_/Roof_ pieces + the doors (decor never blocks players)
--   * sliding doors that open when someone walks up
--   * the big facade screen shows the current banner's rate-up units, rarity, pity and a rotation timer
--   * the summoner spot: press E / click / tap -> opens the Summon screen (LobbyClient handles "Opens")
--   * two more character spots inside; drop real models in ReplicatedStorage.LobbyNPCs later
--   * vertical Neo Tokyo sign text + lights
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))

-- real character models go here later (Models with a PrimaryPart / HumanoidRootPart):
--   ReplicatedStorage.LobbyNPCs.Summoner, .HallGuestL, .HallGuestR
local NPC_FOR_SPOT = { MK_Summoner = "Summoner", MK_ModelSpotL = "HallGuestL", MK_ModelSpotR = "HallGuestR" }

local STYLES = {
	pearl    = { Color = Color3.fromRGB(228, 231, 239), Material = Enum.Material.SmoothPlastic, Reflectance = 0.04 },
	graphite = { Color = Color3.fromRGB(38, 42, 53),   Material = Enum.Material.Metal },
	lavender = { Color = Color3.fromRGB(142, 134, 201), Material = Enum.Material.SmoothPlastic, Reflectance = 0.18 },
	bio      = { Color = Color3.fromRGB(56, 242, 192), Material = Enum.Material.Neon, Glow = true },
	magenta  = { Color = Color3.fromRGB(255, 63, 164), Material = Enum.Material.Neon, Glow = true },
	amber    = { Color = Color3.fromRGB(255, 178, 63), Material = Enum.Material.Neon, Glow = true },
	lantern  = { Color = Color3.fromRGB(232, 65, 58),  Material = Enum.Material.Neon, Glow = true },
	glass    = { Color = Color3.fromRGB(159, 216, 255), Material = Enum.Material.Glass, Transparency = 0.5 },
	screen   = { Color = Color3.fromRGB(10, 14, 28),   Material = Enum.Material.SmoothPlastic },
	floor    = { Color = Color3.fromRGB(27, 31, 43),   Material = Enum.Material.SmoothPlastic, Reflectance = 0.08 },
	cable    = { Color = Color3.fromRGB(17, 19, 24),   Material = Enum.Material.SmoothPlastic },
}
local SIGN_TEXT = { MK_Sign1 = "召喚", MK_Sign2 = "ガチャ", MK_Sign3 = "SUMMON" } -- "summon", "gacha"
local SIGN_COLOR = { MK_Sign1 = Color3.fromRGB(255, 240, 250), MK_Sign2 = Color3.fromRGB(40, 22, 8), MK_Sign3 = Color3.fromRGB(38, 42, 53) }

local INK = Color3.fromRGB(5, 7, 26)
local GOLD = Color3.fromRGB(255, 210, 63)
local BIO = STYLES.bio.Color

local function styleOf(name)
	return name:match("__(%a+)")
end
local function find(model, name)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == name or d.Name:sub(1, #name + 2) == name .. "__") then return d end
	end
end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function text(parent, str, color, font, pos, size, maxSize)
	local l = new("TextLabel", { BackgroundTransparency = 1, Text = str, TextColor3 = color, Font = font or Enum.Font.FredokaOne,
		TextScaled = true, Position = pos, Size = size }, parent)
	if maxSize then new("UITextSizeConstraint", { MaxTextSize = maxSize }, l) end
	return l
end
-- a flat Part facing `dir`, sized from a marker: height = the marker's vertical size,
-- width = its horizontal size across the facade (works for wide screens and tall signs)
local function panelFrom(marker, dir, name, parent)
	local cf, sz = marker.CFrame, marker.Size
	local function extent(axis) -- world-space extent of the marker along a world axis
		return math.abs(cf.RightVector:Dot(axis)) * sz.X + math.abs(cf.UpVector:Dot(axis)) * sz.Y + math.abs(cf.LookVector:Dot(axis)) * sz.Z
	end
	local across = Vector3.yAxis:Cross(dir).Unit
	local pos = marker.Position + dir * 0.12
	return new("Part", { Name = name, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(extent(across), extent(Vector3.yAxis), 0.05), CFrame = CFrame.lookAt(pos, pos + dir) }, parent)
end

---------------------------------------------------------------- banner screen
local function buildScreen(screenPart)
	local sg = new("SurfaceGui", { Name = "BannerScreen", Face = Enum.NormalId.Front, LightInfluence = 0, Brightness = 1.4,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(1360, 600), ClipsDescendants = true }, screenPart)
	new("SurfaceLight", { Face = Enum.NormalId.Front, Range = 26, Brightness = 2, Angle = 110, Color = Color3.fromRGB(180, 170, 255) }, screenPart)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(11, 13, 34), BorderSizePixel = 0 }, sg)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(34, 26, 78), Color3.fromRGB(8, 10, 26)) }, bg)
	-- header
	local head = text(bg, "RATE-UP BANNER", BIO, Enum.Font.FredokaOne, UDim2.fromOffset(40, 22), UDim2.fromOffset(700, 60))
	head.TextXAlignment = Enum.TextXAlignment.Left
	local bname = text(bg, "", Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromOffset(40, 78), UDim2.fromOffset(820, 46))
	bname.TextXAlignment = Enum.TextXAlignment.Left
	local timer = text(bg, "", GOLD, Enum.Font.GothamBold, UDim2.fromOffset(860, 30), UDim2.fromOffset(460, 40))
	timer.TextXAlignment = Enum.TextXAlignment.Right
	local chance = text(bg, ("Featured units get %d%% of their rarity's pulls"):format(math.floor((Config.FeaturedShare or 0.5) * 100)),
		Color3.fromRGB(255, 194, 240), Enum.Font.GothamBold, UDim2.fromOffset(860, 80), UDim2.fromOffset(460, 30))
	chance.TextXAlignment = Enum.TextXAlignment.Right
	local footer = text(bg, ("MYTHIC GUARANTEED AT %d PITY  •  STEP INSIDE TO SUMMON"):format(Config.SummonPity or 50),
		Color3.fromRGB(200, 205, 230), Enum.Font.GothamBold, UDim2.fromOffset(40, 548), UDim2.fromOffset(1280, 34))
	local cards = new("Frame", { Name = "Cards", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 140), Size = UDim2.fromOffset(1360, 400) }, bg)

	local glows = {}
	local shown
	local function draw()
		local banner = Config.GetBanner(os.time())
		if banner == shown then return end
		shown = banner
		bname.Text = string.upper(banner.Name)
		cards:ClearAllChildren()
		table.clear(glows)
		-- middle card (Featured[2]) is the big one
		local layout = { { x = 70, w = 360, h = 330, y = 40 }, { x = 470, w = 420, h = 390, y = 0 }, { x = 930, w = 360, h = 330, y = 40 } }
		for i, id in ipairs(banner.Featured) do
			local def = Config.Units[id]
			local L = layout[i]
			if def and L then
				local rar = Config.Rarities[def.Rarity] or {}
				local rc = rar.Color or Color3.new(1, 1, 1)
				local card = new("Frame", { Position = UDim2.fromOffset(L.x, L.y), Size = UDim2.fromOffset(L.w, L.h), BackgroundColor3 = rc }, cards)
				new("UICorner", { CornerRadius = UDim.new(0, 26) }, card)
				new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 140)) }, card)
				local stroke = new("UIStroke", { Color = i == 2 and GOLD or INK, Thickness = i == 2 and 10 or 7 }, card)
				if def.Rarity == "Mythic" or def.Rarity == "Aegis" then table.insert(glows, stroke) end
				local portrait = new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 22, 50), Position = UDim2.new(0.5, -L.w * 0.3, 0, 18),
					Size = UDim2.fromOffset(L.w * 0.6, L.w * 0.6) }, card)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, portrait)
				new("UIStroke", { Color = INK, Thickness = 5 }, portrait)
				local icon = Icons.Unit[id] and Icons.New(Icons.Unit[id], { Size = UDim2.fromScale(0.86, 0.86), Position = UDim2.fromScale(0.07, 0.07) }, portrait)
				if not icon then
					text(portrait, string.sub(def.DisplayName or id, 1, 1), Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.6, 0.6))
				end
				local nm = text(card, def.DisplayName or id, Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.new(0.05, 0, 0, L.w * 0.6 + 26), UDim2.new(0.9, 0, 0, 56))
				new("UIStroke", { Color = INK, Thickness = 4 }, nm)
				local rt = text(card, string.upper(def.Rarity), Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.new(0.2, 0, 0, L.w * 0.6 + 84), UDim2.new(0.6, 0, 0, 36))
				new("UIStroke", { Color = INK, Thickness = 3 }, rt)
				local chip = new("Frame", { BackgroundColor3 = i == 2 and GOLD or BIO, Position = UDim2.new(0.5, -86, 1, -22), Size = UDim2.fromOffset(172, 44) }, card)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
				new("UIStroke", { Color = INK, Thickness = 4 }, chip)
				text(chip, i == 2 and "FEATURED" or "RATE UP", INK, Enum.Font.FredokaOne, UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.84, 0.76))
			end
		end
	end
	draw()
	task.spawn(function()
		local t = 0
		while sg.Parent do
			draw()
			local rot = Config.BannerRotateSeconds or 3600
			local left = rot - (os.time() % rot)
			timer.Text = ("NEW BANNER IN %02d:%02d"):format(math.floor(left / 60), left % 60)
			t += 1
			for _, s in ipairs(glows) do s.Color = (t % 2 == 0) and GOLD or Color3.fromRGB(255, 120, 230) end
			task.wait(1)
		end
	end)
end

---------------------------------------------------------------- characters
local function holoPlaceholder(marker, label)
	-- a see-through R6 silhouette until a real model is added
	local m = new("Model", { Name = "Placeholder_" .. marker.Name }, marker.Parent)
	local base = marker.Position - Vector3.new(0, marker.Size.Y / 2, 0)
	local look = marker:GetAttribute("FaceDir") or Vector3.new(0, 0, 1)
	local cf = CFrame.lookAt(base, base + look)
	local bits = {
		{ Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) }, { Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0) },
		{ Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0) }, { Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0) },
		{ Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0) }, { Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0) },
	}
	for _, b in ipairs(bits) do
		new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Size = b[1], CFrame = cf * CFrame.new(b[2]),
			Material = Enum.Material.ForceField, Color = BIO, CastShadow = false }, m)
	end
	if label then
		local bb = new("BillboardGui", { Size = UDim2.fromOffset(200, 50), StudsOffsetWorldSpace = Vector3.new(0, 6.6, 0), AlwaysOnTop = false,
			MaxDistance = 60, LightInfluence = 0 }, m:GetChildren()[2])
		local l = text(bb, label, Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		new("UIStroke", { Color = INK, Thickness = 2 }, l)
	end
	return m
end

local function placeCharacter(marker, faceDir, label)
	marker:SetAttribute("FaceDir", faceDir)
	local folder = ReplicatedStorage:FindFirstChild("LobbyNPCs")
	local src = folder and folder:FindFirstChild(NPC_FOR_SPOT[marker.Name] or "")
	if src and src:IsA("Model") then
		local npc = src:Clone()
		for _, p in ipairs(npc:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
		local _, size = npc:GetBoundingBox()
		local mid = marker.Position - Vector3.new(0, marker.Size.Y / 2, 0) + Vector3.new(0, size.Y / 2, 0)
		npc:PivotTo(CFrame.lookAt(mid, mid + faceDir))
		npc.Parent = marker.Parent
		return npc
	end
	return holoPlaceholder(marker, label)
end

local function makePressable(marker, npc)
	marker.CanQuery = true
	new("ProximityPrompt", { ActionText = "Summon", ObjectText = "Summoner", KeyboardKeyCode = Enum.KeyCode.E,
		MaxActivationDistance = 14, RequiresLineOfSight = false, HoldDuration = 0 }, marker):SetAttribute("Opens", "Summon")
	local cd = new("ClickDetector", { MaxActivationDistance = 40 }, marker)
	cd:SetAttribute("Opens", "Summon")
	if npc then
		for _, p in ipairs(npc:GetDescendants()) do if p:IsA("BasePart") then p.CanQuery = false end end
	end
end

---------------------------------------------------------------- doors
local function setupDoors(model)
	local L, R = find(model, "DoorL"), find(model, "DoorR")
	if not (L and R) then return end
	local axis = (R.Position - L.Position)
	local slide = axis.Magnitude * 0.96
	axis = axis.Unit
	local homeL, homeR = L.CFrame, R.CFrame
	local mid = (L.Position + R.Position) / 2
	local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local open = false
	task.spawn(function()
		while model.Parent do
			local near = false
			for _, plr in ipairs(Players:GetPlayers()) do
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - mid).Magnitude < 17 then near = true break end
			end
			if near ~= open then
				open = near
				TweenService:Create(L, info, { CFrame = open and (homeL - axis * slide) or homeL }):Play()
				TweenService:Create(R, info, { CFrame = open and (homeR + axis * slide) or homeR }):Play()
			end
			task.wait(0.2)
		end
	end)
end

---------------------------------------------------------------- setup
local function setup(model)
	if model:GetAttribute("HallReady") then return end
	model:SetAttribute("HallReady", true)
	local center, front = find(model, "MK_Center"), find(model, "MK_Front")
	local fwd = Vector3.new(0, 0, 1)
	if center and front then
		local d = (front.Position - center.Position) * Vector3.new(1, 0, 1)
		if d.Magnitude > 0.1 then fwd = d.Unit end
	end
	local lanternLit = false
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			if p.Name:sub(1, 3) == "MK_" then
				p.Transparency = 1
				p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
			else
				local st = STYLES[styleOf(p.Name) or ""]
				if st then
					p.Color = st.Color
					p.Material = st.Material
					p.Reflectance = st.Reflectance or 0
					p.Transparency = st.Transparency or 0
					if st.Glow then p.CastShadow = false end
				end
				if p:IsA("MeshPart") then p.TextureID = "" end
				local solid = p.Name:match("^Wall_") or p.Name:match("^Floor_") or p.Name:match("^Roof_") or p.Name:match("^Door[LR]")
				p.CanCollide = solid ~= nil
				p.CanTouch = false
				p.CanQuery = solid ~= nil
				if styleOf(p.Name) == "lantern" and not lanternLit then
					lanternLit = true
					new("PointLight", { Color = Color3.fromRGB(255, 150, 90), Range = 30, Brightness = 1.6 }, p)
				end
			end
		end
	end
	-- interior light
	if center then
		local a = new("Attachment", { WorldPosition = center.Position + Vector3.new(0, 14, 0) }, center)
		new("PointLight", { Color = Color3.fromRGB(170, 255, 230), Range = 50, Brightness = 1.4, Shadows = true }, a)
	end
	-- screen
	local mkScreen = find(model, "MK_Screen")
	if mkScreen then buildScreen(panelFrom(mkScreen, fwd, "BannerScreenPanel", model)) end
	-- signs
	for mk, str in pairs(SIGN_TEXT) do
		local m = find(model, mk)
		if m then
			local panel = panelFrom(m, fwd, mk .. "_Text", model)
			local vertical = panel.Size.Y > panel.Size.X
			local sg = new("SurfaceGui", { Face = Enum.NormalId.Front, LightInfluence = 0, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
				PixelsPerStud = 30 }, panel)
			local s = str
			if vertical then -- one character per line (UTF-8 aware)
				local chars = {}
				for _, c in utf8.codes(str) do table.insert(chars, utf8.char(c)) end
				s = table.concat(chars, "\n")
			end
			local l = text(sg, s, SIGN_COLOR[mk] or Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.94))
			l.LineHeight = 0.9
		end
	end
	-- characters: summoner faces the door, guests face the room centre
	local summoner = find(model, "MK_Summoner")
	if summoner then
		local npc = placeCharacter(summoner, fwd, "SUMMONER")
		makePressable(summoner, npc)
	end
	for _, name in ipairs({ "MK_ModelSpotL", "MK_ModelSpotR" }) do
		local m = find(model, name)
		if m then
			local toMid = center and ((center.Position - m.Position) * Vector3.new(1, 0, 1)) or fwd
			placeCharacter(m, (toMid.Magnitude > 0.1 and toMid.Unit) or fwd, nil)
		end
	end
	setupDoors(model)
	print("[SummonHall] ready:", model:GetFullName())
end

local function tryModel(inst)
	if inst:IsA("BasePart") and inst.Name == "MK_Summoner" then
		-- the hall = the nearest ancestor Model that also holds the doors (works if you group it further)
		local model = inst:FindFirstAncestorOfClass("Model")
		while model and not find(model, "DoorL") and model.Parent:IsA("Model") do
			model = model.Parent
		end
		if model then task.defer(setup, model) end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do tryModel(d) end
workspace.DescendantAdded:Connect(tryModel)
