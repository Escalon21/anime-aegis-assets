-- PlayClient v2 (LocalScript) -> StarterGui.PlayGui
-- The Play screen, redesigned in Figma ("Anime Aegis - Play Screen v2"): slanted anime cards, speed lines,
-- glowing party stage, and the motion spec (open sequence, idle loops, hover/press, detail slide, countdown burst).
--   left:   your party (cloned characters in a ViewportFrame) + "+" invite slots
--   right:  Story hero card (continue + progress), Aegis Mode, Infinite, 3 "coming soon" tiles -> details + START
--   bottom: Back / Invite / Join Party (Leave Party when you're in someone else's party)
-- Server side: LobbyService "Parties" (remotes Party, PartyUpdate, PartyInvite) + StartMatch.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Icons = require(ReplicatedStorage:WaitForChild("Icons"))
local PartyRemote = ReplicatedStorage:WaitForChild("Party")
local PartyUpdate = ReplicatedStorage:WaitForChild("PartyUpdate")
local PartyInvite = ReplicatedStorage:WaitForChild("PartyInvite")
local StartMatch = ReplicatedStorage:WaitForChild("StartMatch")
local gui = script.Parent

local INK = Color3.fromRGB(5, 7, 26)
local WHITE = Color3.new(1, 1, 1)
local LILAC = Color3.fromRGB(201, 184, 255)
local GOLD = Color3.fromRGB(255, 210, 63)
local ORANGE = Color3.fromRGB(255, 138, 31)
local PINK = Color3.fromRGB(255, 63, 164)
local CYAN = Color3.fromRGB(47, 230, 255)
local GREEN = Color3.fromRGB(31, 194, 122)
local RED = Color3.fromRGB(230, 60, 70)
local GREY = Color3.fromRGB(96, 98, 118)
local LUCKY = Enum.Font.LuckiestGuy
local FONT = Enum.Font.FredokaOne
local BLACK = Enum.Font.GothamBlack
local BOLD = Enum.Font.GothamBold
local W, H = 1600, 900

---------------------------------------------------------------- helpers
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end
local function O(x, y) return UDim2.fromOffset(x, y) end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o) end
local function border(o, color, th)
	return new("UIStroke", { Color = color or INK, Thickness = th or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function label(parent, props, size, color, align, font, stroke)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = font or FONT, TextColor3 = color or WHITE, TextScaled = true,
		TextXAlignment = align or Enum.TextXAlignment.Center, Text = "" }, parent)
	for k, v in pairs(props) do l[k] = v end
	new("UITextSizeConstraint", { MaxTextSize = size or 20 }, l)
	if stroke ~= 0 then new("UIStroke", { Color = INK, Thickness = stroke or ((size or 20) >= 24 and 2.6 or 1.6) }, l) end
	return l
end
local LEFT = Enum.TextXAlignment.Left
local function gloss(o, top, bottom)
	return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(top or WHITE, bottom or Color3.fromRGB(170, 170, 185)) }, o)
end
local function tween(o, t, props, style, dir, rep, rev, delay)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false, delay or 0), props)
	tw:Play()
	return tw
end
local function button(parent, props, text, color, textSize)
	local b = new("TextButton", { BackgroundColor3 = color, Text = "", AutoButtonColor = true }, parent)
	for k, v in pairs(props) do b[k] = v end
	corner(b, 12)
	border(b, INK, 3)
	gloss(b)
	local t = label(b, { Name = "Label", Position = O(10, 6), Size = UDim2.new(1, -20, 1, -12), Text = text }, textSize or 26)
	return b, t
end
local function icon(name, props, parent) return Icons.New(name, props, parent) end
local function decode(attr, default)
	local ok, v = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(attr) or "")
	return ok and v or default
end

-- slanted parallelogram ("/" sides): a Frame whose UIGradient transparency cuts the two slanted edges
local function slantPiece(parent, x, y, w, h, s, c1, c2, props)
	w = math.max(w, s + 2) -- a parallelogram needs a top edge (w includes the slant)
	local f = new("Frame", { Position = O(x, y), Size = O(w, h), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, parent)
	local th = math.atan2(s, h)
	local span = w * math.cos(th) + h * math.sin(th)
	local tl, tr, e = s * math.cos(th) / span, w * math.cos(th) / span, 0.003
	new("UIGradient", { Rotation = math.deg(th), Color = ColorSequence.new(c1, c2 or c1), Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(tl - e, 1), NumberSequenceKeypoint.new(tl, 0),
		NumberSequenceKeypoint.new(tr, 0), NumberSequenceKeypoint.new(tr + e, 1), NumberSequenceKeypoint.new(1, 1) }) }, f)
	for k, v in pairs(props or {}) do f[k] = v end
	return f
end
-- Roblox stretches rotated gradients on very wide/thin frames, so long shapes are built from
-- two slanted end caps + a plain middle strip (same outline, no stretching)
local function slant(parent, x, y, w, h, s, c1, c2, props)
	if w / h <= 4.6 or h < s then return slantPiece(parent, x, y, w, h, s, c1, c2, props) end
	local box = new("Frame", { Position = O(x, y), Size = O(w, h), BackgroundTransparency = 1 }, parent)
	box:SetAttribute("Wide", true)
	local capW = s + h
	slantPiece(box, 0, 0, capW, h, s, c1, c1, { Name = "L" })
	slantPiece(box, w - capW, 0, capW, h, s, c2 or c1, c2 or c1, { Name = "R" })
	local mid = new("Frame", { Name = "M", Position = O(h, 0), Size = O(w - 2 * h, h), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, box)
	new("UIGradient", { Color = ColorSequence.new(c1, c2 or c1) }, mid)
	for k, v in pairs(props or {}) do
		if k == "BackgroundTransparency" then
			for _, p in ipairs(box:GetChildren()) do p.BackgroundTransparency = v end
		else
			box[k] = v
		end
	end
	return box
end
local function setSlantColor(f, c1, c2)
	if f:GetAttribute("Wide") then
		f.L.UIGradient.Color = ColorSequence.new(c1)
		f.R.UIGradient.Color = ColorSequence.new(c2 or c1)
		f.M.UIGradient.Color = ColorSequence.new(c1, c2 or c1)
	else
		f.UIGradient.Color = ColorSequence.new(c1, c2 or c1)
	end
end
-- slanted box with a dark outline (outline = a slightly bigger ink parallelogram behind)
local function slantBox(parent, x, y, w, h, s, c1, c2)
	local outline = slant(parent, x - 6, y - 5, w + 12, h + 10, s * (h + 10) / h, INK, INK, { Name = "Outline" })
	local fill = slant(parent, x, y, w, h, s, c1, c2, { Name = "Fill" })
	return fill, outline
end
local function hoverScale(target, holder, amount)
	local sc = new("UIScale", {}, target)
	holder.MouseEnter:Connect(function() tween(sc, 0.12, { Scale = amount or 1.06 }) end)
	holder.MouseLeave:Connect(function() tween(sc, 0.12, { Scale = 1 }) end)
	holder.MouseButton1Down:Connect(function() tween(sc, 0.06, { Scale = 0.94 }) end)
	holder.MouseButton1Up:Connect(function() tween(sc, 0.1, { Scale = amount or 1.06 }) end)
	return sc
end
-- slanted button: returns the click target (TextButton) and its label
local function slantButton(parent, x, y, w, h, s, c1, c2, text, size)
	local b = new("TextButton", { Position = O(x, y), Size = O(w, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
	local vis = new("Frame", { Name = "Vis", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, b)
	slantBox(vis, 6, 5, w - 12, h - 10, s, c1, c2)
	local t = label(vis, { Name = "Label", Position = O(s * 0.6 + 12, 10), Size = O(w - s - 30, h - 20), Text = text }, size or 32, WHITE, Enum.TextXAlignment.Center, LUCKY, 3)
	hoverScale(vis, b)
	return b, t, vis
end

---------------------------------------------------------------- root + scaling
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 8

local root = new("Frame", { Name = "PlayFrame", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 12, 36),
	BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, gui)
new("UIGradient", { Rotation = 0, Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 17, 82)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(18, 14, 58)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 31)) }) }, root)
local canvas = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(W, H), BackgroundTransparency = 1 }, root)
local scale = new("UIScale", {}, canvas)
local scales = { scale }
local function fit()
	local vp = workspace.CurrentCamera.ViewportSize
	local s = math.min(vp.X / W, vp.Y / H)
	for _, sc in ipairs(scales) do sc.Scale = s end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- toast (outside the play screen so invites/notices show anywhere)
local toastFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -130), Size = O(620, 54),
	BackgroundColor3 = Color3.fromRGB(20, 22, 60), Visible = false, ZIndex = 50 }, gui)
corner(toastFrame, 14) border(toastFrame, GOLD, 3)
table.insert(scales, new("UIScale", {}, toastFrame))
local toastText = label(toastFrame, { Position = O(14, 8), Size = UDim2.new(1, -28, 1, -16), ZIndex = 51 }, 22)
local toastId = 0
local function toast(msg)
	toastId += 1
	local id = toastId
	toastText.Text = tostring(msg)
	toastFrame.Visible = true
	task.delay(3, function() if toastId == id then toastFrame.Visible = false end end)
end

---------------------------------------------------------------- state
local state = { party = nil, detail = nil, selectedAct = nil, lastCount = 0 }
local function isLeader() return not state.party or state.party.Host == player.UserId end
local function members() return state.party and state.party.Members or { player.UserId } end

---------------------------------------------------------------- background FX (speed lines + sparks)
local lines = new("Frame", { Name = "SpeedLines", Position = O(-500, -300), Size = O(2800, 1600), BackgroundTransparency = 1 }, canvas)
for i = 0, 34 do
	local col = (i % 4 == 0) and PINK or CYAN
	new("Frame", { Position = O(i * 78, 0), Size = O(4 + (i % 3) * 3, 1700), Rotation = -28, BorderSizePixel = 0,
		BackgroundColor3 = col, BackgroundTransparency = 0.95 - (i % 3) * 0.02 }, lines)
end
local sparks = {}
for i = 1, 18 do
	local s = 4 + (i % 3) * 2
	local sp = new("Frame", { Size = O(s, s), BackgroundColor3 = (i % 2 == 0) and GOLD or CYAN, BorderSizePixel = 0 }, canvas)
	corner(sp, s)
	sparks[i] = sp
end

---------------------------------------------------------------- header
local header = new("CanvasGroup", { Position = O(36, 26), Size = O(720, 80), BackgroundTransparency = 1 }, canvas)
slantBox(header, 6, 3, 594, 72, 32, GOLD, ORANGE)
slant(header, 604, 3, 70 + 12, 72, 32, PINK)
slant(header, 664, 3, 40 + 12, 72, 32, CYAN)
label(header, { Position = O(34, 8), Size = O(520, 64), Text = "SELECT MODE" }, 64, WHITE, LEFT, LUCKY, 4)
local headerShine = slant(header, -200, 0, 90 + 32, 80, 32, WHITE, WHITE, { BackgroundTransparency = 0.55 })
local headerSub = label(canvas, { Position = O(74, 110), Size = O(560, 22), Text = "YOUR PARTY FOLLOWS THE LEADER" }, 17, LILAC, LEFT, BLACK, 0)

---------------------------------------------------------------- LEFT: party stage
local stage = new("Frame", { Position = O(30, 140), Size = O(600, 660), BackgroundTransparency = 1 }, canvas)
local partyCount = label(stage, { Position = O(20, 0), Size = O(300, 32), Text = "PARTY 1/4" }, 30, WHITE, LEFT, LUCKY, 3)
local partyInfo = label(stage, { Position = O(22, 36), Size = O(560, 24) }, 20, LILAC, LEFT, FONT, 0)
-- pulsing glow behind the party
local glowHolder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = O(300, 380), Size = O(560, 520), BackgroundTransparency = 1 }, stage)
local glowScale = new("UIScale", {}, glowHolder)
for i, s in ipairs({ 1, 0.72, 0.46 }) do
	local g = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s),
		BackgroundColor3 = Color3.fromRGB(138, 60, 255), BackgroundTransparency = 0.9 - i * 0.02, BorderSizePixel = 0 }, glowHolder)
	corner(g, 400)
end

local VP_W, VP_H = 600, 600
-- 2D platform under the leader (drawn behind the viewport)
local platform = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = O(360, 90), BackgroundColor3 = Color3.fromRGB(58, 44, 140), BorderSizePixel = 0 }, stage)
corner(platform, 200)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(80, 64, 190), Color3.fromRGB(20, 15, 63)) }, platform)
local platformGlow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = O(230, 44), BackgroundColor3 = CYAN, BackgroundTransparency = 0.5, BorderSizePixel = 0 }, stage)
corner(platformGlow, 200)
local orbit = {}
for i = 1, 14 do
	local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = O(12, 6), BackgroundColor3 = CYAN, BorderSizePixel = 0 }, stage)
	corner(d, 6)
	orbit[i] = d
end

local vpf = new("ViewportFrame", { Position = O(0, 60), Size = O(VP_W, VP_H), BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(160, 150, 200), LightColor = Color3.fromRGB(255, 244, 230), LightDirection = Vector3.new(-0.5, -1, 0.7) }, stage)
local world = new("WorldModel", {}, vpf)
local cam = new("Camera", { FieldOfView = 36 }, vpf)
vpf.CurrentCamera = cam
local CAM_POS, CAM_AT = Vector3.new(-1, 5.2, -20), Vector3.new(-1, 2.7, 1.8)
cam.CFrame = CFrame.lookAt(CAM_POS, CAM_AT)
local SLOTS = { Vector3.new(0, 0, 0), Vector3.new(4.3, 0, 2.6), Vector3.new(-3.4, 0, 4.2), Vector3.new(-6.3, 0, 1.2) }
local rings = {}
for i, pos in ipairs(SLOTS) do
	if i > 1 then
		rings[i] = new("Part", { Anchored = true, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 3.6, 3.6), Material = Enum.Material.Neon,
			CFrame = CFrame.new(pos + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = GREY }, world)
	end
end
local overlay = new("Frame", { Position = vpf.Position, Size = vpf.Size, BackgroundTransparency = 1 }, stage)
local function project(p)
	local rel = cam.CFrame:PointToObjectSpace(p)
	local d = math.max(-rel.Z, 0.1)
	local t = math.tan(math.rad(cam.FieldOfView / 2))
	return Vector2.new(VP_W / 2 + rel.X / (d * t * (VP_W / VP_H)) * VP_W / 2, VP_H / 2 - rel.Y / (d * t) * VP_H / 2)
end
local feet = project(SLOTS[1]) + Vector2.new(0, 60) -- stage coords (viewport sits 60px down)
platform.Position = O(feet.X, feet.Y)
platformGlow.Position = O(feet.X, feet.Y + 4)

local plusButtons, nameTags, pulseTweens = {}, {}, {}
for i, pos in ipairs(SLOTS) do
	local tag = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = O(220, 66), BackgroundTransparency = 1, Visible = false }, overlay)
	new("UIScale", { Name = "Pop" }, tag)
	label(tag, { Name = "NameText", Position = O(0, 30), Size = O(220, 34) }, 30, WHITE, Enum.TextXAlignment.Center, FONT, 3)
	local chip = new("Frame", { Name = "Leader", AnchorPoint = Vector2.new(0.5, 0), Position = O(110, 0), Size = O(104, 26), BackgroundColor3 = GOLD }, tag)
	corner(chip, 13) border(chip, INK, 3)
	label(chip, { Position = O(6, 3), Size = UDim2.new(1, -12, 1, -6), Text = "LEADER" }, 18, INK, Enum.TextXAlignment.Center, LUCKY, 0)
	nameTags[i] = tag
	if i > 1 then
		local p2 = project(pos + Vector3.new(0, 2.6, 0))
		local plus = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = O(p2.X, p2.Y), Size = O(68, 68), BackgroundColor3 = Color3.fromRGB(124, 255, 107), Text = "", AutoButtonColor = false }, overlay)
		corner(plus, 16) border(plus, INK, 4)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(124, 255, 107), Color3.fromRGB(31, 168, 58)) }, plus)
		label(plus, { Position = O(8, 4), Size = O(52, 58), Text = "+" }, 56, WHITE, Enum.TextXAlignment.Center, LUCKY, 3)
		label(plus, { Position = O(-20, 72), Size = O(108, 18), Text = "INVITE" }, 15, Color3.fromRGB(158, 242, 164), Enum.TextXAlignment.Center, BLACK, 0)
		local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(92, 92), BackgroundTransparency = 1, ZIndex = 0 }, plus)
		corner(ring, 60)
		local rs = new("UIStroke", { Color = Color3.fromRGB(70, 224, 90), Thickness = 3 }, ring)
		local rsc = new("UIScale", {}, ring)
		pulseTweens[i] = { ring = rsc, stroke = rs }
		hoverScale(plus, plus, 1.08)
		plusButtons[i] = plus
	end
end

local shownKey, shownCount = "", 0
local shownModels = {}
local function dummy()
	local m = new("Model", { Name = "Dummy" })
	local parts = { { Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) }, { Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0) },
		{ Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0) }, { Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0) },
		{ Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0) }, { Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0) } }
	for _, p in ipairs(parts) do
		new("Part", { Anchored = true, Size = p[1], CFrame = CFrame.new(p[2]), Color = Color3.fromRGB(120, 120, 150) }, m)
	end
	return m
end
local function cloneCharacter(uid)
	local plr = Players:GetPlayerByUserId(uid)
	local ch = plr and plr.Character
	if ch and ch:FindFirstChild("HumanoidRootPart") then
		local was = ch.Archivable
		ch.Archivable = true
		local ok, c = pcall(function() return ch:Clone() end)
		ch.Archivable = was
		if ok and c then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("ForceField") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			local hum = c:FindFirstChildOfClass("Humanoid")
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			return c
		end
	end
	return dummy()
end
local basePivots = {}
local function placeModel(m, pos)
	local cf, size = m:GetBoundingBox()
	local lift = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
	local at = pos + Vector3.new(0, lift, 0)
	m:PivotTo(CFrame.lookAt(at, Vector3.new(CAM_POS.X, at.Y, CAM_POS.Z)))
	basePivots[m] = m:GetPivot()
	return size.Y
end

local function refreshParty()
	local list = members()
	local key = table.concat(list, ",")
	local grew = #list > shownCount and shownKey ~= ""
	if key ~= shownKey then
		shownKey = key
		for _, m in ipairs(shownModels) do basePivots[m] = nil m:Destroy() end
		table.clear(shownModels)
		for i, uid in ipairs(list) do
			if SLOTS[i] then
				local m = cloneCharacter(uid)
				m.Parent = world
				m:SetAttribute("H", placeModel(m, SLOTS[i]))
				shownModels[i] = m
			end
		end
	end
	local p = state.party
	local leaderId = p and p.Host or player.UserId
	for i, pos in ipairs(SLOTS) do
		local uid = list[i]
		local filled = uid ~= nil
		if rings[i] then rings[i].Color = filled and CYAN or Color3.fromRGB(70, 64, 120) end
		local tag = nameTags[i]
		local wasVisible = tag.Visible
		tag.Visible = filled
		if filled then
			local plr = Players:GetPlayerByUserId(uid)
			tag.NameText.Text = plr and plr.DisplayName or ((p and p.Names and p.Names[i]) or "Player")
			tag.Leader.Visible = uid == leaderId
			local h = (shownModels[i] and shownModels[i]:GetAttribute("H")) or 5.5
			local pt = project(pos + Vector3.new(0, h + 0.5, 0))
			tag.Position = O(pt.X, pt.Y)
			if grew and not wasVisible then -- someone joined: pop the slot
				tag.Pop.Scale = 0
				tween(tag.Pop, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
		if plusButtons[i] then plusButtons[i].Visible = not filled and isLeader() end
	end
	shownCount = #list
	partyCount.Text = ("PARTY %d/4"):format(#list)
	local modeText = p and p.Label or "Choosing a mode..."
	partyInfo.Text = isLeader() and modeText or (modeText .. "  •  leader: " .. (p.HostName or "?"))
end

---------------------------------------------------------------- data helpers
local function actMapName(act) return (act.Name:gsub("^Act %d+:%s*", "")) end
local function clearedActs() return decode("ClearedActs", {}) end
local function currentAct()
	local cleared = clearedActs()
	for _, a in ipairs(Config.Stages.Story) do
		if not cleared[a.Id] and (not a.RequiresAct or cleared[a.RequiresAct]) then return a end
	end
	return Config.Stages.Story[#Config.Stages.Story]
end
local function aegisMod()
	local ok, m = pcall(Config.GetAegisModifier)
	return ok and m or { Name = "Standard Protocol" }
end

---------------------------------------------------------------- RIGHT: mode cards
local modes = new("Frame", { Name = "Modes", Size = O(W, H), BackgroundTransparency = 1 }, canvas)
local cards = {} -- in entry order
local cardRefs = {}
local function card(def)
	local x, y, w, h, s = def.X, def.Y, def.W, def.H, def.S
	local holder = new("TextButton", { Name = def.Id, Position = O(x - 6, y - 5), Size = O(w + 12, h + 10), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, modes)
	local sc = new("UIScale", {}, holder)
	local glow = slant(holder, -10, -8, w + 32, h + 26, s * (h + 26) / h, GOLD, ORANGE, { Name = "Glow", BackgroundTransparency = 1 })
	local group = new("CanvasGroup", { Name = "Group", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, holder)
	local fill, outline = slantBox(group, 6, 5, w, h, s, def.C1, def.C2)
	local inner = new("Frame", { Name = "Inner", Position = O(6, 5), Size = O(w, h), BackgroundTransparency = 1 }, group)
	slant(inner, w * 0.52 - s, 0, w * 0.18 + s, h, s, WHITE, WHITE, { BackgroundTransparency = 0.92 })
	slant(inner, w * 0.74 - s, 0, w * 0.06 + s, h, s, WHITE, WHITE, { BackgroundTransparency = 0.94 })
	local big = h > 230
	local num = label(inner, { Name = "Number", Position = O(w - s - (big and 270 or 170), big and 10 or 4), Size = O(big and 240 or 150, big and 220 or 150), Text = def.Num,
		TextTransparency = 0.88, TextXAlignment = Enum.TextXAlignment.Right }, big and 220 or 150, WHITE, Enum.TextXAlignment.Right, LUCKY, 0)
	local refs = { Holder = holder, Scale = sc, Glow = glow, Group = group, Outline = outline, Number = num, NumX = num.Position.X.Offset, Def = def, Inner = inner }
	label(inner, { Position = O(s + 22, 12), Size = O(w - s - 60, big and 70 or 52), Text = def.Title }, big and 68 or 50, WHITE, LEFT, LUCKY, 4)
	if def.Sub then
		label(inner, { Position = O(s + 24, big and 86 or 66), Size = O(w - s - 60, 18), Text = def.Sub }, 16, WHITE, LEFT, BLACK, 0).TextTransparency = 0.15
	end
	refs.Line1 = label(inner, { Position = O(s + 14, big and 118 or 94), Size = O(w - s - 40, 32) }, big and 30 or 26, WHITE, LEFT, FONT, 2.2)
	refs.Line2 = label(inner, { Position = O(s + 6, big and 152 or 126), Size = O(big and 560 or 220, 24) }, 19, Color3.fromRGB(228, 224, 255), LEFT, FONT, 0)
	if def.Progress then
		local bg = new("Frame", { Position = O(24, h - 46), Size = O(360, 16), BackgroundColor3 = INK, BackgroundTransparency = 0.45, BorderSizePixel = 0 }, inner)
		corner(bg, 8)
		local f = new("Frame", { Size = O(16, 16), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, bg)
		corner(f, 8)
		new("UIGradient", { Color = ColorSequence.new(GOLD, ORANGE) }, f)
		refs.ProgressFill = f
		refs.ProgressLabel = label(inner, { Position = O(400, h - 50), Size = O(260, 22) }, 17, WHITE, LEFT, BLACK, 0)
	end
	if def.Cta then
		local cx, cy = big and (w - 250) or (w - 196), big and 16 or (h - 54)
		slant(inner, cx, cy, big and 200 or 170, 44, 16, INK, INK, { BackgroundTransparency = 0.35 })
		refs.Cta = label(inner, { Position = O(cx + 26, cy + 8), Size = O((big and 200 or 170) - 44, 28), Text = def.Cta }, 26, GOLD, LEFT, LUCKY, 0)
	end
	if def.Soon then
		slant(inner, 0, 0, w, h, s, INK, INK, { BackgroundTransparency = 0.45 })
		local stripes = new("Frame", { Name = "Stripes", Position = O(0, h - 22), Size = O(w + 80, 22), BackgroundTransparency = 1 }, inner)
		for i = 0, math.floor(w / 40) + 2 do slant(stripes, i * 40 - 40, 0, 20 + 10, 22, 10, GOLD, GOLD, { BackgroundTransparency = 0.2 }) end
		refs.Stripes = stripes
		label(inner, { Position = O(44, 66), Size = O(w - 70, 26), Text = "COMING SOON" }, 24, GOLD, LEFT, LUCKY, 3)
	end
	-- the recurring shine (hero card)
	if def.Shine then refs.Shine = slant(inner, -220, 0, 110 + s, h, s, WHITE, WHITE, { BackgroundTransparency = 0.7 }) end
	holder.MouseEnter:Connect(function()
		tween(sc, 0.15, { Scale = 1.04 })
		tween(glow, 0.15, { BackgroundTransparency = def.Soon and 0.85 or 0.45 })
		setSlantColor(outline, def.Soon and INK or GOLD)
		tween(num, 0.2, { Position = O(refs.NumX - 20, num.Position.Y.Offset) })
	end)
	holder.MouseLeave:Connect(function()
		tween(sc, 0.15, { Scale = 1 })
		tween(glow, 0.15, { BackgroundTransparency = 1 })
		setSlantColor(outline, INK)
		tween(num, 0.2, { Position = O(refs.NumX, num.Position.Y.Offset) })
	end)
	holder.MouseButton1Click:Connect(function()
		if def.Soon then
			local px = holder.Position.X.Offset
			for i, dx in ipairs({ -6, 6, -4, 4, 0 }) do task.delay((i - 1) * 0.05, function() holder.Position = O(px + dx, holder.Position.Y.Offset) end) end
			toast(def.Title .. " is coming in a future update!")
			return
		end
		tween(sc, 0.06, { Scale = 0.96 })
		task.delay(0.07, function() if def.OnClick then def.OnClick() end end)
	end)
	cardRefs[def.Id] = refs
	table.insert(cards, refs)
	return refs
end

---------------------------------------------------------------- detail view
local detail = new("Frame", { Name = "Detail", Size = O(W, H), BackgroundTransparency = 1, Visible = false }, canvas)
local DX, DY = 700, 140
local backToModes = slantButton(detail, DX - 6, DY - 16, 190, 56, 18, Color3.fromRGB(140, 143, 168), Color3.fromRGB(74, 76, 99), "< MODES", 26)
local dPlate = slant(detail, DX + 200, DY - 22, 560, 74, 30, WHITE, WHITE)
local dTitle = label(detail, { Position = O(DX + 236, DY - 18), Size = O(500, 66) }, 58, WHITE, LEFT, LUCKY, 4)
local dSub = label(detail, { Position = O(DX + 210, DY + 60), Size = O(640, 22) }, 17, LILAC, LEFT, BLACK, 0)
local dBody = new("Frame", { Position = O(DX, DY + 100), Size = O(860, 450), BackgroundTransparency = 1 }, detail)
local startGlow = slant(detail, DX + 500, DY + 552, 380, 104, 36, GOLD, ORANGE, { BackgroundTransparency = 0.6 })
local startBtn, startText, startVis = slantButton(detail, DX + 510, DY + 560, 360, 88, 32, GOLD, ORANGE, "START", 56)
local startNote = label(detail, { Position = O(DX, DY + 572), Size = O(490, 66), TextWrapped = true }, 20, LILAC, LEFT, BOLD, 0)

local function statTile(parent, x, title, value, color)
	local t = new("Frame", { Position = O(x, 0), Size = O(280, 120), BackgroundColor3 = Color3.fromRGB(26, 22, 72) }, parent)
	corner(t, 14) border(t, INK, 3)
	local bar = new("Frame", { Size = O(280, 8), BackgroundColor3 = color, BorderSizePixel = 0 }, t)
	corner(bar, 4)
	label(t, { Position = O(16, 18), Size = O(250, 24), Text = title }, 20, color:Lerp(WHITE, 0.3), LEFT, LUCKY, 0)
	label(t, { Position = O(16, 46), Size = O(250, 58), Text = value }, 46, WHITE, LEFT, LUCKY, 3)
end
local function bodyText(parent, y, h, text)
	return label(parent, { Position = O(4, y), Size = O(850, h), Text = text, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top }, 24, WHITE, LEFT, FONT, 0)
end
local function rewardLine(parent, y, iconName, text, color)
	local f = new("Frame", { Position = O(0, y), Size = O(850, 58), BackgroundColor3 = Color3.fromRGB(27, 22, 80) }, parent)
	corner(f, 12) border(f, INK, 3)
	local tile = new("Frame", { Position = O(8, 6), Size = O(46, 46), BackgroundColor3 = color }, f)
	corner(tile, 10) border(tile, INK, 2) gloss(tile)
	icon(iconName, { Position = O(4, 4), Size = O(38, 38) }, tile)
	label(f, { Position = O(68, 12), Size = O(770, 34), Text = text }, 24, WHITE, LEFT, FONT, 0)
end

local currentStart
local function refreshStartButton()
	local p = state.party
	if p and p.Countdown then
		startText.Text = isLeader() and "CANCEL" or ("STARTING " .. p.Countdown)
	elseif isLeader() then
		startText.Text = "START"
	else
		startText.Text = "WAITING"
	end
	startVis.Visible = true
	local n = #members()
	if isLeader() then
		startNote.Text = n > 1 and ("Everyone in your party (%d/4) joins this battle."):format(n) or "Playing solo. Invite friends with the + slots or Invite."
	else
		startNote.Text = ("%s is the party leader and picks the mode."):format(p and p.HostName or "The leader")
	end
end
startBtn.MouseButton1Click:Connect(function()
	if state.party and state.party.Countdown then
		if isLeader() then PartyRemote:InvokeServer("Cancel") end
		return
	end
	if not isLeader() then toast("Only the party leader can start") return end
	if currentStart then currentStart() end
end)
local function launch(mode, actId)
	local ok, err = StartMatch:InvokeServer(mode, actId)
	if not ok then toast(err or "Couldn't start") end
end

local showModes
local function slideTo(showDetail)
	-- modes slide out left / detail slides in from the right (and back)
	local out, inn = showDetail and modes or detail, showDetail and detail or modes
	inn.Visible = true
	inn.Position = O(showDetail and 300 or -300, 0)
	tween(inn, 0.3, { Position = O(0, 0) }, Enum.EasingStyle.Quint)
	tween(out, 0.3, { Position = O(showDetail and -300 or 300, 0) }, Enum.EasingStyle.Quint)
	task.delay(0.3, function() if out ~= (state.detail and detail or modes) then out.Visible = false end end)
end

local function openDetail(kind)
	state.detail = kind
	dBody:ClearAllChildren()
	local def = cardRefs[kind] and cardRefs[kind].Def
	if def then setSlantColor(dPlate, def.C1, def.C2) end
	if kind == "Story" then
		dTitle.Text = "STORY"
		dSub.Text = "PICK AN ACT  •  CLEAR IT TO UNLOCK THE NEXT ONE"
		local cleared = clearedActs()
		state.selectedAct = state.selectedAct or currentAct().Id
		local list = new("Frame", { Size = O(860, 450), BackgroundTransparency = 1 }, dBody)
		new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		local rows = {}
		local function paint()
			for id, r in pairs(rows) do
				local on = id == state.selectedAct
				r.Stroke.Color = on and GOLD or INK
				r.Stroke.Thickness = on and 5 or 3
				tween(r.Scale, 0.12, { Scale = on and 1.015 or 1 })
			end
		end
		for i, act in ipairs(Config.Stages.Story) do
			local locked = act.RequiresAct and not cleared[act.RequiresAct]
			local done = cleared[act.Id]
			local r = new("TextButton", { LayoutOrder = i, Size = O(850, 100), BackgroundColor3 = locked and Color3.fromRGB(38, 36, 58) or Color3.fromRGB(28, 36, 96), Text = "", AutoButtonColor = not locked }, list)
			corner(r, 14)
			local st = border(r, INK, 3)
			local rsc = new("UIScale", {}, r)
			new("UIGradient", { Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 170, 200)) }, r)
			local strip = new("Frame", { Size = O(14, 100), BackgroundColor3 = locked and GREY or Color3.fromRGB(46, 140, 255), BorderSizePixel = 0 }, r)
			corner(strip, 7)
			label(r, { Position = O(32, 10), Size = O(580, 38), Text = act.Name:upper() }, 34, locked and Color3.fromRGB(170, 170, 185) or WHITE, LEFT, LUCKY, 3)
			local drops = {}
			local md = Config.MaterialDrops and Config.MaterialDrops[act.Id]
			if md and md.Mats then for _, m in ipairs(md.Mats) do table.insert(drops, m[1]) end end
			label(r, { Position = O(34, 52), Size = O(620, 22), Text = ("+%d Gems  •  +%d XP%s"):format(act.RewardGems or 0, act.RewardXP or 0, #drops > 0 and ("  •  " .. table.concat(drops, ", ")) or "") }, 20, Color3.fromRGB(215, 220, 245), LEFT, FONT, 0)
			label(r, { Position = O(34, 74), Size = O(620, 20), Text = locked and ("Clear " .. tostring(act.RequiresAct) .. " to unlock") or ("Enemy HP x" .. tostring(act.HpScale or 1)) }, 17, locked and GOLD or LILAC, LEFT, BOLD, 0)
			local chipColor = locked and GREY or (done and GREEN or GOLD)
			slant(r, 670, 28, 160, 44, 14, chipColor, chipColor)
			label(r, { Position = O(690, 34), Size = O(124, 32), Text = locked and "LOCKED" or (done and "CLEARED" or "NEW") }, 26, WHITE, Enum.TextXAlignment.Center, LUCKY, 2.5)
			rows[act.Id] = { Stroke = st, Scale = rsc }
			r.MouseButton1Click:Connect(function()
				if locked then toast("Clear " .. tostring(act.RequiresAct) .. " first!") return end
				state.selectedAct = act.Id
				paint()
			end)
		end
		paint()
		currentStart = function() launch("Story", state.selectedAct) end
	elseif kind == "Infinite" then
		dTitle.Text = "INFINITE"
		dSub.Text = "COMPETITIVE  •  ENDLESS WAVES"
		statTile(dBody, 0, "YOUR BEST WAVE", tostring(player:GetAttribute("BestInfiniteWave") or 0), Color3.fromRGB(150, 90, 255))
		statTile(dBody, 300, "LEADERBOARD", "TOP WAVES", GOLD)
		bodyText(dBody, 150, 110, "The waves never stop and every wave hits harder. Survive as long as you can - your best wave goes on the Top Waves board.")
		rewardLine(dBody, 270, "gems", "Gems and XP that grow with every wave you survive", Color3.fromRGB(80, 170, 255))
		rewardLine(dBody, 340, "topwaves", "A spot on the Top Waves leaderboard", GOLD)
		currentStart = function() launch("Infinite") end
	elseif kind == "Aegis" then
		local mod = aegisMod()
		dTitle.Text = "AEGIS MODE"
		dSub.Text = "SPECIAL  •  DEFEND THE AEGIS CORE"
		statTile(dBody, 0, "YOUR BEST WAVE", tostring(player:GetAttribute("BestAegisWave") or 0), Color3.fromRGB(30, 200, 190))
		statTile(dBody, 300, "THIS WEEK", mod.Name or "?", GOLD)
		local desc = mod.Description or mod.Desc or ""
		bodyText(dBody, 150, 100, "Protect the Aegis core with your team and buy core upgrades between waves." .. (desc ~= "" and ("  This week: " .. desc) or ""))
		rewardLine(dBody, 250, "shards", "Aegis Shards for the Shard Shop", Color3.fromRGB(40, 220, 200))
		rewardLine(dBody, 320, "evolve", "Hero Emblem - evolution item, only drops here", Color3.fromRGB(255, 150, 60))
		rewardLine(dBody, 390, "crystal", "Very rare: an Aegis unit (from wave 10)", Color3.fromRGB(80, 230, 255))
		currentStart = function() launch("Aegis") end
	end
	refreshStartButton()
	if not detail.Visible or modes.Visible then slideTo(true) end
end

local function refreshCards()
	local cleared = clearedActs()
	local n, total = 0, #Config.Stages.Story
	for _, a in ipairs(Config.Stages.Story) do if cleared[a.Id] then n += 1 end end
	local cur = currentAct()
	local s = cardRefs.Story
	s.Line1.Text = n >= total and "All acts cleared!" or ("Continue: " .. cur.Name:gsub("^Act (%d+):%s*", "Act %1 - "))
	local md = Config.MaterialDrops and Config.MaterialDrops[cur.Id]
	local drops = {}
	if md and md.Mats then for _, m in ipairs(md.Mats) do table.insert(drops, m[1]) end end
	s.Line2.Text = ("+%d Gems  •  +%d XP%s"):format(cur.RewardGems or 0, cur.RewardXP or 0, #drops > 0 and ("  •  " .. table.concat(drops, ", ")) or "")
	s.ProgressTarget = n / total
	s.ProgressLabel.Text = ("%d%%  TOTAL PROGRESS"):format(math.floor(n / total * 100 + 0.5))
	cardRefs.Aegis.Line1.Text = aegisMod().Name or "?"
	cardRefs.Aegis.Line2.Text = ("Best wave %d"):format(player:GetAttribute("BestAegisWave") or 0)
	cardRefs.Infinite.Line1.Text = "Top Waves board"
	cardRefs.Infinite.Line2.Text = ("Best wave %d"):format(player:GetAttribute("BestInfiniteWave") or 0)
end

showModes = function()
	state.detail = nil
	refreshCards()
	if detail.Visible then slideTo(false) end
end
backToModes.MouseButton1Click:Connect(function() showModes() end)

card({ Id = "Story", X = 700, Y = 140, W = 860, H = 250, S = 44, C1 = Color3.fromRGB(46, 140, 255), C2 = Color3.fromRGB(18, 48, 122),
	Title = "STORY", Sub = "PROGRESSIVE  •  4 ACTS", Num = "01", Cta = "CONTINUE >", Progress = true, Shine = true, OnClick = function() openDetail("Story") end })
card({ Id = "Aegis", X = 700, Y = 412, W = 420, H = 210, S = 36, C1 = Color3.fromRGB(30, 200, 190), C2 = Color3.fromRGB(11, 74, 87),
	Title = "AEGIS", Sub = "SPECIAL  •  WEEKLY", Num = "02", Cta = "VIEW >", OnClick = function() openDetail("Aegis") end })
card({ Id = "Infinite", X = 1140, Y = 412, W = 420, H = 210, S = 36, C1 = Color3.fromRGB(150, 90, 255), C2 = Color3.fromRGB(53, 22, 111),
	Title = "INFINITE", Sub = "COMPETITIVE  •  ENDLESS", Num = "03", Cta = "VIEW >", OnClick = function() openDetail("Infinite") end })
for i, t in ipairs({ { "Raid", Color3.fromRGB(230, 60, 60), Color3.fromRGB(74, 13, 22) }, { "Boss Rush", Color3.fromRGB(215, 50, 190), Color3.fromRGB(62, 11, 64) },
	{ "Challenge", Color3.fromRGB(255, 160, 40), Color3.fromRGB(77, 42, 6) } }) do
	card({ Id = t[1]:gsub(" ", ""), X = 700 + (i - 1) * 290, Y = 644, W = 270, H = 140, S = 26, C1 = t[2], C2 = t[3], Title = t[1]:upper(), Num = "0" .. (3 + i), Soon = true })
end

---------------------------------------------------------------- countdown burst
local cd = new("Frame", { Name = "Countdown", AnchorPoint = Vector2.new(0.5, 0.5), Position = O(1130, 460), Size = O(480, 420), BackgroundColor3 = Color3.fromRGB(10, 9, 30), BackgroundTransparency = 0, Visible = false, ZIndex = 10 }, canvas)
corner(cd, 24) border(cd, GOLD, 3)
local cdRings = {}
for i, r in ipairs({ 330, 250, 180 }) do
	local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = O(240, 190), Size = O(r, r), BackgroundTransparency = 1, ZIndex = 11 }, cd)
	corner(ring, r)
	cdRings[i] = { Stroke = new("UIStroke", { Color = GOLD, Thickness = 6, Transparency = 0.2 + i * 0.2 }, ring), Scale = new("UIScale", {}, ring) }
end
local cdNum = label(cd, { AnchorPoint = Vector2.new(0.5, 0.5), Position = O(240, 190), Size = O(240, 220), Text = "3", ZIndex = 12 }, 220, WHITE, Enum.TextXAlignment.Center, LUCKY, 7)
cdNum.TextScaled = false
cdNum.TextSize = 100 -- Roblox's maximum text size
local cdNumScale = new("UIScale", {}, cdNum)
local cdLabel = label(cd, { Position = O(20, 336), Size = O(440, 34), ZIndex = 12 }, 30, GOLD, Enum.TextXAlignment.Center, LUCKY, 3)
local cdCancel = slantButton(cd, 150, 366, 180, 50, 16, RED, Color3.fromRGB(140, 20, 40), "CANCEL", 26)
cdCancel.ZIndex = 12
for _, d in ipairs(cdCancel:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 13 end end
cdCancel.Position = O(150, 372)
cdCancel.MouseButton1Click:Connect(function() PartyRemote:InvokeServer("Cancel") end)
-- white flash as the battle loads (lives outside the play screen, so it survives the screen closing)
local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 60, Visible = false }, gui)
local function refreshCountdown()
	local p = state.party
	local c = p and p.Countdown
	if c then
		cd.Visible = true
		cdLabel.Text = (p.Label or ""):upper()
		cdCancel.Visible = isLeader()
		if c ~= state.lastCount then
			cdNum.Text = tostring(c)
			-- text can't render above 100px, so the burst pops UP from small (0.25 -> 1, Back overshoot)
			cdNumScale.Scale = 0.25
			cdNum.TextTransparency = 1
			cdNum.Rotation = -12
			tween(cdNumScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(cdNum, 0.35, { Rotation = 0 }, Enum.EasingStyle.Back)
			tween(cdNum, 0.25, { TextTransparency = 0 })
			for i, r in ipairs(cdRings) do
				r.Scale.Scale = 0.6
				r.Stroke.Transparency = 0.1
				tween(r.Scale, 0.6 + i * 0.1, { Scale = 1.5 }, Enum.EasingStyle.Quint)
				tween(r.Stroke, 0.6 + i * 0.1, { Transparency = 1 })
			end
		end
		state.lastCount = c
	else
		cd.Visible = false
		state.lastCount = 0
	end
end

---------------------------------------------------------------- bottom bar
local bar = new("Frame", { Name = "BottomBar", Position = O(-400, 808), Size = O(W + 800, 120), BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, canvas)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.4, 0) }, bar)
local backBtn = slantButton(canvas, 30, 818, 214, 72, 20, Color3.fromRGB(140, 143, 168), Color3.fromRGB(74, 76, 99), "BACK", 36)
local inviteBtn = slantButton(canvas, 1034, 818, 262, 72, 20, Color3.fromRGB(58, 160, 255), Color3.fromRGB(21, 83, 201), "INVITE", 36)
local joinBtn, joinText, joinVis = slantButton(canvas, 1304, 818, 272, 72, 20, Color3.fromRGB(176, 102, 255), Color3.fromRGB(91, 31, 201), "JOIN PARTY", 34)
local function refreshBar()
	local inOthers = state.party and state.party.Host ~= player.UserId
	joinText.Text = inOthers and "LEAVE PARTY" or "JOIN PARTY"
	local fill = joinVis:FindFirstChild("Fill")
	if fill then
		if inOthers then setSlantColor(fill, RED, Color3.fromRGB(140, 20, 40)) else setSlantColor(fill, Color3.fromRGB(176, 102, 255), Color3.fromRGB(91, 31, 201)) end
	end
	inviteBtn.Visible = isLeader()
end

---------------------------------------------------------------- popups (invite list / join list)
local shade = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20 }, root)
local modal = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(640, 600), BackgroundColor3 = Color3.fromRGB(20, 18, 62), ZIndex = 21, Active = true }, shade)
corner(modal, 20) border(modal, GOLD, 4)
local modalScale = new("UIScale", {}, modal)
table.insert(scales, modalScale)
local mTitle = label(modal, { Position = O(24, 16), Size = O(480, 50), ZIndex = 22 }, 44, WHITE, LEFT, LUCKY, 3)
local mClose = button(modal, { Position = O(572, 16), Size = O(50, 50), ZIndex = 22 }, "X", RED, 26)
for _, d in ipairs(mClose:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 23 end end
local mList = new("ScrollingFrame", { Position = O(20, 80), Size = O(600, 500), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22 }, modal)
local mEmpty = label(modal, { Position = O(40, 260), Size = O(560, 80), ZIndex = 23, TextWrapped = true }, 26, LILAC)
local function closeModal() shade.Visible = false end
mClose.MouseButton1Click:Connect(closeModal)
shade.MouseButton1Click:Connect(closeModal)

local function headshot(parent, uid, z)
	local img = new("ImageLabel", { Position = O(10, 8), Size = O(56, 56), BackgroundColor3 = Color3.fromRGB(40, 44, 100), ZIndex = z }, parent)
	corner(img, 28) border(img, INK, 2)
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok then img.Image = url end
	end)
end
local function listRow(i, uid, name, sub, btnText, btnColor, onClick)
	local r = new("Frame", { Position = O(0, (i - 1) * 84), Size = O(580, 72), BackgroundColor3 = Color3.fromRGB(30, 30, 86), ZIndex = 23 }, mList)
	corner(r, 14) border(r, INK, 3)
	headshot(r, uid, 24)
	label(r, { Position = O(80, 8), Size = O(300, 32), Text = name, ZIndex = 24 }, 26, WHITE, LEFT)
	label(r, { Position = O(80, 40), Size = O(300, 22), Text = sub, ZIndex = 24 }, 18, LILAC, LEFT, BOLD)
	local b = button(r, { Position = O(408, 12), Size = O(160, 48), ZIndex = 24 }, btnText, btnColor, 22)
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 25 end end
	if onClick then b.MouseButton1Click:Connect(function() onClick(b) end) else b.AutoButtonColor = false end
end
local function openList(kind)
	for _, c in ipairs(mList:GetChildren()) do c:Destroy() end
	shade.Visible = true
	modal.Position = UDim2.new(0.5, 0, 0.5, 40)
	tween(modal, 0.25, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
	mEmpty.Text = "Loading..."
	if kind == "Invite" then
		mTitle.Text = "INVITE PLAYERS"
		local ok, list = PartyRemote:InvokeServer("Players")
		list = ok and list or {}
		mEmpty.Text = #list == 0 and "Nobody else is in this server yet." or ""
		for i, e in ipairs(list) do
			local sub = e.InMatch and "In a battle" or (e.Invited and "Invite sent" or "In the lobby")
			if e.InMatch then
				listRow(i, e.UserId, e.Name, sub, "Busy", GREY, nil)
			else
				listRow(i, e.UserId, e.Name, sub, e.Invited and "Sent" or "Invite", e.Invited and GREY or Color3.fromRGB(47, 123, 255), function(b)
					local ok2, err = PartyRemote:InvokeServer("Invite", e.Player)
					if ok2 then b.Label.Text = "Sent" b.BackgroundColor3 = GREY toast("Invite sent to " .. e.Name) else toast(err) end
				end)
			end
		end
	else
		mTitle.Text = "JOIN A PARTY"
		local ok, list = PartyRemote:InvokeServer("List")
		list = ok and list or {}
		mEmpty.Text = #list == 0 and "No open parties right now. Start your own and invite people!" or ""
		for i, e in ipairs(list) do
			listRow(i, e.Host, e.Name .. "'s party", ("%d/%d  •  %s"):format(e.Count, e.Max, e.Label), "Join", GREEN, function()
				local ok2, err = PartyRemote:InvokeServer("Join", e.Host)
				if ok2 then closeModal() toast("Joined " .. e.Name .. "'s party!") else toast(err) end
			end)
		end
	end
end

---------------------------------------------------------------- invite notification (shows even with the Play screen closed)
local inviteCard = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 96), Size = O(440, 150), BackgroundColor3 = Color3.fromRGB(20, 18, 62), Visible = false, ZIndex = 40 }, gui)
corner(inviteCard, 18) border(inviteCard, GOLD, 4)
table.insert(scales, new("UIScale", {}, inviteCard))
local invTitle = label(inviteCard, { Position = O(18, 12), Size = O(404, 34), ZIndex = 41 }, 30, WHITE, LEFT, LUCKY, 3)
local invSub = label(inviteCard, { Position = O(18, 48), Size = O(404, 24), ZIndex = 41 }, 20, LILAC, LEFT, BOLD)
local invJoin = button(inviteCard, { Position = O(18, 86), Size = O(196, 50), ZIndex = 41 }, "Join", GREEN, 24)
local invNo = button(inviteCard, { Position = O(226, 86), Size = O(196, 50), ZIndex = 41 }, "Decline", GREY, 24)
for _, d in ipairs(inviteCard:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 42) end end
local pendingHost, inviteId = nil, 0
invJoin.MouseButton1Click:Connect(function()
	inviteCard.Visible = false
	if not pendingHost then return end
	local ok, err = PartyRemote:InvokeServer("Accept", pendingHost)
	if ok then
		toast("You joined the party!")
		if not root.Visible and player:GetAttribute("InMatch") ~= true then root.Visible = true end
	else
		toast(err)
	end
end)
invNo.MouseButton1Click:Connect(function() inviteCard.Visible = false end)
PartyInvite.OnClientEvent:Connect(function(info)
	if info.Notice then toast(info.Notice) return end
	pendingHost = info.Host
	invTitle.Text = info.Name:upper() .. " INVITED YOU!"
	invSub.Text = info.Label or ""
	inviteCard.Visible = true
	inviteCard.Position = UDim2.new(1, 460, 0, 96)
	tween(inviteCard, 0.35, { Position = UDim2.new(1, -24, 0, 96) }, Enum.EasingStyle.Back)
	inviteId += 1
	local id = inviteId
	task.delay(15, function() if inviteId == id then inviteCard.Visible = false end end)
end)

---------------------------------------------------------------- animation: open sequence + idle loops
local loops = {}
local function stopLoops()
	for _, tw in ipairs(loops) do tw:Cancel() end
	table.clear(loops)
end
local function loop(o, t, props, style, rev, delay)
	local tw = tween(o, t, props, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, rev, delay)
	table.insert(loops, tw)
	return tw
end
local function playOpen()
	stopLoops()
	-- backdrop
	root.BackgroundTransparency = 1
	tween(root, 0.25, { BackgroundTransparency = 0 })
	-- header slides in + shine
	header.Position = O(-700, 26)
	tween(header, 0.35, { Position = O(36, 26) }, Enum.EasingStyle.Back)
	headerShine.Position = O(-200, 0)
	tween(headerShine, 0.6, { Position = O(760, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0.35)
	headerSub.TextTransparency = 1
	tween(headerSub, 0.3, { TextTransparency = 0 }, nil, nil, 0, false, 0.25)
	-- party stage rises
	stage.Position = O(30, 180)
	vpf.ImageTransparency = 1
	tween(stage, 0.4, { Position = O(30, 140) }, Enum.EasingStyle.Quint, nil, 0, false, 0.1)
	tween(vpf, 0.4, { ImageTransparency = 0 }, nil, nil, 0, false, 0.1)
	-- cards fly in one by one
	for i, c in ipairs(cards) do
		local x, y = c.Def.X - 6, c.Def.Y - 5
		c.Holder.Position = O(x + 140, y)
		c.Group.GroupTransparency = 1
		c.Scale.Scale = 1
		tween(c.Holder, 0.32, { Position = O(x, y) }, Enum.EasingStyle.Quint, nil, 0, false, 0.15 + (i - 1) * 0.07)
		tween(c.Group, 0.32, { GroupTransparency = 0 }, Enum.EasingStyle.Quint, nil, 0, false, 0.15 + (i - 1) * 0.07)
	end
	-- progress bar fills
	local s = cardRefs.Story
	if s.ProgressFill then
		s.ProgressFill.Size = O(16, 16)
		tween(s.ProgressFill, 0.8, { Size = O(math.max(16, 360 * (s.ProgressTarget or 0)), 16) }, Enum.EasingStyle.Quint, nil, 0, false, 0.45)
	end
	-- bottom buttons slide up
	for i, b in ipairs({ backBtn, inviteBtn, joinBtn }) do
		local x = b.Position.X.Offset
		b.Position = O(x, 920)
		tween(b, 0.3, { Position = O(x, 818) }, Enum.EasingStyle.Back, nil, 0, false, 0.2 + i * 0.05)
	end
	-- idle loops
	lines.Position = O(-500, -300)
	table.insert(loops, tween(lines, 6, { Position = O(-500 + 312, -300) }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
	glowScale.Scale = 1
	loop(glowScale, 2, { Scale = 1.08 }, nil, true)
	platformGlow.BackgroundTransparency = 0.65
	loop(platformGlow, 1.6, { BackgroundTransparency = 0.4 }, nil, true)
	for i, p in pairs(pulseTweens) do
		p.ring.Scale = 1
		p.stroke.Transparency = 0.2
		table.insert(loops, tween(p.ring, 1.2, { Scale = 1.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, (i - 2) * 0.3))
		table.insert(loops, tween(p.stroke, 1.2, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, (i - 2) * 0.3))
	end
	for _, c in ipairs(cards) do
		if c.Stripes then
			c.Stripes.Position = O(0, c.Def.H - 22)
			table.insert(loops, tween(c.Stripes, 1.5, { Position = O(-40, c.Def.H - 22) }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1))
		end
	end
	startGlow.BackgroundTransparency = 0.7
	loop(startGlow, 0.9, { BackgroundTransparency = 0.35 }, nil, true)
end

-- per-frame bits: sparks drifting, platform orbit dots, avatar bob, hero card shine
local sparkState = {}
for i, sp in ipairs(sparks) do
	sparkState[i] = { x = 40 + (i * 97) % 600, y = 200 + (i * 131) % 600, v = 20 + (i % 5) * 8, life = (i * 0.37) % 1 }
end
local shineT = 0
RunService.RenderStepped:Connect(function(dt)
	if not root.Visible then return end
	local t = os.clock()
	for i, sp in ipairs(sparks) do
		local st = sparkState[i]
		st.life += dt / (3 + (i % 4))
		if st.life > 1 then st.life = 0 st.x = 30 + math.random() * 600 st.y = 300 + math.random() * 500 end
		sp.Position = O(st.x + math.sin(t + i) * 10, st.y - st.life * 180)
		sp.BackgroundTransparency = 0.1 + st.life * 0.9
	end
	for i, d in ipairs(orbit) do
		local a = t * (math.pi * 2 / 8) + i * (math.pi * 2 / #orbit)
		d.Position = O(feet.X + math.cos(a) * 205, feet.Y + math.sin(a) * 52)
		d.BackgroundTransparency = 0.2 + (math.sin(a) < 0 and 0.5 or 0) -- dots behind the leader fade
		d.Rotation = math.deg(math.atan2(math.cos(a) * 52, -math.sin(a) * 205))
	end
	for i, m in ipairs(shownModels) do
		local base = basePivots[m]
		if base then m:PivotTo(base * CFrame.new(0, math.sin(t * 2.6 + i * 1.3) * 0.12, 0)) end
	end
	shineT += dt
	local s = cardRefs.Story
	if s and s.Shine and not state.detail then
		local phase = shineT % 4
		s.Shine.Position = O(phase < 0.6 and (-220 + (phase / 0.6) * (s.Def.W + 440)) or -220, 0)
	end
end)

---------------------------------------------------------------- wiring
local function refreshAll()
	refreshParty()
	refreshBar()
	refreshCountdown()
	if state.detail then refreshStartButton() end
end
PartyUpdate.OnClientEvent:Connect(function(snap)
	state.party = snap
	if not snap and root.Visible and player:GetAttribute("InMatch") ~= true then
		task.delay(0.5, function()
			if root.Visible and not state.party then
				local ok, s = PartyRemote:InvokeServer("Open")
				if ok then state.party = s refreshAll() end
			end
		end)
	end
	refreshAll()
end)

backBtn.MouseButton1Click:Connect(function() root.Visible = false end)
inviteBtn.MouseButton1Click:Connect(function() openList("Invite") end)
for _, b in pairs(plusButtons) do b.MouseButton1Click:Connect(function() openList("Invite") end) end
joinBtn.MouseButton1Click:Connect(function()
	if state.party and state.party.Host ~= player.UserId then
		local ok, s = PartyRemote:InvokeServer("Leave")
		if ok then state.party = s refreshAll() toast("You left the party") end
	else
		openList("Join")
	end
end)

local function onVisible()
	local lobbyGui = player.PlayerGui:FindFirstChild("LobbyGui")
	local layer = lobbyGui and lobbyGui:FindFirstChild("LobbyLayer")
	if layer then layer.Visible = (not root.Visible) and player:GetAttribute("InMatch") ~= true end
	if root.Visible then
		fit()
		state.detail = nil
		modes.Visible, modes.Position = true, O(0, 0)
		detail.Visible = false
		refreshCards()
		shownKey = ""
		playOpen()
		task.spawn(function()
			local ok, s = PartyRemote:InvokeServer("Open")
			if ok then state.party = s end
			refreshAll()
		end)
		refreshAll()
	else
		stopLoops()
		closeModal()
	end
end
root:GetPropertyChangedSignal("Visible"):Connect(onVisible)
player:GetAttributeChangedSignal("InMatch"):Connect(function()
	if player:GetAttribute("InMatch") then
		if state.lastCount > 0 or cd.Visible then
			flash.Visible = true
			flash.BackgroundTransparency = 0
			tween(flash, 0.6, { BackgroundTransparency = 1 })
			task.delay(0.65, function() flash.Visible = false end)
		end
		root.Visible = false
		inviteCard.Visible = false
	end
end)
-- test hook (like GameClient.DebugSelect): DebugPlay:Invoke("Story" | "Aegis" | "Infinite" | "Start" | "Modes" | "Invite" | "Join")
local hook = Instance.new("BindableFunction")
hook.Name = "DebugPlay"
hook.OnInvoke = function(what)
	if what == "Start" then if currentStart then currentStart() end
	elseif what == "Modes" then showModes()
	elseif what == "Invite" or what == "Join" then openList(what)
	else openDetail(what) end
	return true
end
hook.Parent = script
fit()
refreshCards()
refreshAll()
