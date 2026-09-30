-- PlayClient (LocalScript) -> StarterGui.PlayGui
-- The Play screen (replaces the physical Battle Gates):
--   left:   your party - your character + 3 more slots ("+" = invite), leader tag
--   right:  game-mode cards in sections (Progressive / Special / Competitive), "Click to view" -> details + Start
--   bottom: Back / Invite Players / Join Party (Leave Party when you're in someone else's party)
-- Server side: LobbyService "Parties" (remotes Party, PartyUpdate, PartyInvite) + StartMatch.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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
local GREEN = Color3.fromRGB(31, 194, 122)
local PURPLE = Color3.fromRGB(138, 60, 255)
local RED = Color3.fromRGB(230, 60, 70)
local GREY = Color3.fromRGB(96, 98, 118)
local FONT = Enum.Font.FredokaOne
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
local function label(parent, props, size, color, align, font)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = font or FONT, TextColor3 = color or WHITE, TextScaled = true,
		TextXAlignment = align or Enum.TextXAlignment.Center, Text = "" }, parent)
	for k, v in pairs(props) do l[k] = v end
	new("UITextSizeConstraint", { MaxTextSize = size or 20 }, l)
	new("UIStroke", { Color = INK, Thickness = (size or 20) >= 24 and 2.6 or 1.6 }, l)
	return l
end
local function gloss(o, top, bottom)
	return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(top or WHITE, bottom or Color3.fromRGB(170, 170, 185)) }, o)
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
local function icon(name, props, parent)
	return Icons.New(name, props, parent)
end
local function decode(attr, default)
	local ok, v = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(attr) or "")
	return ok and v or default
end

---------------------------------------------------------------- root + scaling
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 8

local root = new("Frame", { Name = "PlayFrame", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 12, 36),
	BorderSizePixel = 0, Visible = false }, gui)
new("UIGradient", { Rotation = 0, Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 40, 128)),
	ColorSequenceKeypoint.new(0.42, Color3.fromRGB(26, 24, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 28)) }) }, root)
local canvas = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(W, H), BackgroundTransparency = 1 }, root)
local scale = new("UIScale", {}, canvas)
local scales = { scale }
local function fit()
	local vp = workspace.CurrentCamera.ViewportSize
	local s = math.min(vp.X / W, vp.Y / H)
	for _, sc in ipairs(scales) do sc.Scale = s end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- toast (lives outside the play screen so invites/notices show anywhere)
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
local state = { party = nil, detail = nil, selectedAct = nil }
local function isLeader()
	return not state.party or state.party.Host == player.UserId
end
local function members()
	return state.party and state.party.Members or { player.UserId }
end

---------------------------------------------------------------- LEFT: party viewport
local left = new("Frame", { Position = O(24, 24), Size = O(640, 780), BackgroundTransparency = 1 }, canvas)
label(left, { Position = O(8, 0), Size = O(420, 44), Text = "YOUR PARTY" }, 36, WHITE, Enum.TextXAlignment.Left)
local partyInfo = label(left, { Position = O(10, 44), Size = O(600, 26) }, 20, LILAC, Enum.TextXAlignment.Left)

local VP_W, VP_H = 640, 700
local vpf = new("ViewportFrame", { Position = O(0, 80), Size = O(VP_W, VP_H), BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(150, 150, 185), LightColor = Color3.fromRGB(255, 244, 230), LightDirection = Vector3.new(-0.5, -1, 0.7) }, left)
local world = new("WorldModel", {}, vpf)
local cam = new("Camera", { FieldOfView = 36 }, vpf)
vpf.CurrentCamera = cam
local CAM_POS, CAM_AT = Vector3.new(1.3, 4.6, -16), Vector3.new(1.3, 2.3, 1.8)
cam.CFrame = CFrame.lookAt(CAM_POS, CAM_AT)
local SLOTS = { Vector3.new(0, 0, 0), Vector3.new(-4.4, 0, 2.6), Vector3.new(3.8, 0, 4.0), Vector3.new(6.9, 0, 1.2) }

new("Part", { Anchored = true, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 34, 34), Material = Enum.Material.SmoothPlastic,
	CFrame = CFrame.new(1, -0.2, 3) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(44, 36, 100) }, world)
local rings = {}
for i, pos in ipairs(SLOTS) do
	rings[i] = new("Part", { Anchored = true, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 3.8, 3.8), Material = Enum.Material.Neon,
		CFrame = CFrame.new(pos + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = GREY }, world)
end

local overlay = new("Frame", { Position = vpf.Position, Size = vpf.Size, BackgroundTransparency = 1 }, left)
local function project(p)
	local rel = cam.CFrame:PointToObjectSpace(p)
	local d = math.max(-rel.Z, 0.1)
	local t = math.tan(math.rad(cam.FieldOfView / 2))
	return O(VP_W / 2 + rel.X / (d * t * (VP_W / VP_H)) * VP_W / 2, VP_H / 2 - rel.Y / (d * t) * VP_H / 2)
end
local plusButtons, nameTags = {}, {}
for i, pos in ipairs(SLOTS) do
	local tag = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = O(210, 58), BackgroundTransparency = 1, Visible = false }, overlay)
	local nm = label(tag, { Name = "NameText", Position = O(0, 26), Size = O(210, 30) }, 24)
	local chip = new("Frame", { Name = "Leader", AnchorPoint = Vector2.new(0.5, 0), Position = O(105, 0), Size = O(96, 24), BackgroundColor3 = GOLD }, tag)
	corner(chip, 12) border(chip, INK, 2)
	label(chip, { Position = O(4, 2), Size = UDim2.new(1, -8, 1, -4), Text = "LEADER" }, 16, INK)
	nameTags[i] = tag
	if i > 1 then
		local plus = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Size = O(62, 62), BackgroundColor3 = Color3.fromRGB(70, 200, 60), Text = "" }, overlay)
		corner(plus, 12) border(plus, INK, 3) gloss(plus)
		label(plus, { Position = O(6, 2), Size = O(50, 56), Text = "+" }, 48)
		plus.Position = project(pos + Vector3.new(0, 2.6, 0))
		plusButtons[i] = plus
	end
end

local shownKey = ""
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
local function placeModel(m, pos)
	local cf, size = m:GetBoundingBox()
	local lift = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
	local at = pos + Vector3.new(0, lift, 0)
	m:PivotTo(CFrame.lookAt(at, Vector3.new(CAM_POS.X, at.Y, CAM_POS.Z)))
	return size.Y
end

local function refreshParty()
	local list = members()
	local key = table.concat(list, ",")
	if key ~= shownKey then
		shownKey = key
		for _, m in ipairs(shownModels) do m:Destroy() end
		table.clear(shownModels)
		for i, uid in ipairs(list) do
			if SLOTS[i] then
				local m = cloneCharacter(uid)
				m.Parent = world
				local h = placeModel(m, SLOTS[i])
				m:SetAttribute("H", h)
				shownModels[i] = m
			end
		end
	end
	local p = state.party
	local leaderId = p and p.Host or player.UserId
	for i, pos in ipairs(SLOTS) do
		local uid = list[i]
		local filled = uid ~= nil
		rings[i].Color = filled and Color3.fromRGB(47, 230, 255) or GREY
		local tag = nameTags[i]
		tag.Visible = filled
		if filled then
			local plr = Players:GetPlayerByUserId(uid)
			tag.NameText.Text = plr and plr.DisplayName or ((p and p.Names and p.Names[i]) or "Player")
			tag.Leader.Visible = uid == leaderId
			local h = (shownModels[i] and shownModels[i]:GetAttribute("H")) or 5.5
			tag.Position = project(pos + Vector3.new(0, h + 0.5, 0))
		end
		if plusButtons[i] then plusButtons[i].Visible = not filled and isLeader() end
	end
	local modeText = p and p.Label or "Choosing a mode"
	partyInfo.Text = ("%d/%d players  •  %s"):format(#list, 4, isLeader() and modeText or (modeText .. "  •  leader: " .. (p.HostName or "?")))
end

---------------------------------------------------------------- RIGHT: mode cards
local right = new("ScrollingFrame", { Position = O(684, 24), Size = O(900, 772), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, ScrollBarImageColor3 = Color3.fromRGB(140, 120, 230), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, canvas)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 24) }, right)
new("UIListLayout", { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder }, right)

local order = 0
local function nextOrder() order += 1 return order end
local function ribbon(text, color)
	local holder = new("Frame", { LayoutOrder = nextOrder(), Size = O(860, 70), BackgroundTransparency = 1 }, right)
	local r = new("Frame", { Position = O(36, 8), Size = O(400, 56), BackgroundColor3 = color }, holder)
	corner(r, 28) border(r, INK, 4)
	new("UIGradient", { Rotation = 0, Color = ColorSequence.new(color:Lerp(WHITE, 0.25), color:Lerp(INK, 0.35)) }, r)
	label(r, { Position = O(64, 8), Size = O(320, 40), Text = text }, 34, WHITE, Enum.TextXAlignment.Left)
	-- ornament medallion
	local med = new("Frame", { Position = O(0, 0), Size = O(72, 72), BackgroundColor3 = color:Lerp(INK, 0.2) }, holder)
	corner(med, 36) border(med, INK, 4)
	local inner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(44, 44), BackgroundColor3 = color:Lerp(WHITE, 0.35) }, med)
	corner(inner, 22) border(inner, INK, 3)
	return holder
end
local function row()
	local r = new("Frame", { LayoutOrder = nextOrder(), Size = O(870, 224), BackgroundTransparency = 1 }, right)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder }, r)
	return r
end

local cardRefs = {}
local function card(parent, def)
	local c = new("TextButton", { Name = def.Id, LayoutOrder = def.Order or 0, Size = O(426, 224), BackgroundColor3 = def.Color, AutoButtonColor = false, Text = "" }, parent)
	corner(c, 16)
	border(c, INK, 4)
	new("UIGradient", { Rotation = 110, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, def.Color:Lerp(INK, 0.35)),
		ColorSequenceKeypoint.new(0.55, def.Color:Lerp(INK, 0.62)),
		ColorSequenceKeypoint.new(1, def.Color:Lerp(INK, 0.8)) }) }, c)
	local sc = new("UIScale", {}, c)
	-- "art": light streak + big faded icon
	local streak = new("Frame", { Position = O(120, -40), Size = O(60, 320), Rotation = 28, BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, BorderSizePixel = 0 }, c)
	local streak2 = new("Frame", { Position = O(200, -40), Size = O(18, 320), Rotation = 28, BackgroundColor3 = WHITE, BackgroundTransparency = 0.93, BorderSizePixel = 0 }, c)
	c.ClipsDescendants = true
	if def.Icon then icon(def.Icon, { Position = O(262, 8), Size = O(150, 150), ImageTransparency = 0.78, Rotation = -10 }, c) end
	local refs = {}
	label(c, { Position = O(18, 10), Size = O(330, 50), Text = def.Title }, 46, def.Color:Lerp(WHITE, 0.3), Enum.TextXAlignment.Left)
	label(c, { Position = O(18, 58), Size = O(330, 24), Text = def.Sub }, 20, WHITE, Enum.TextXAlignment.Left)
	refs.Label1 = label(c, { Position = O(18, 92), Size = O(250, 22) }, 19, def.Color:Lerp(WHITE, 0.2), Enum.TextXAlignment.Left)
	refs.Value1 = label(c, { Position = O(18, 114), Size = O(250, 30) }, 27, WHITE, Enum.TextXAlignment.Left)
	refs.Value2 = label(c, { Position = O(18, 144), Size = O(250, 22) }, 19, Color3.fromRGB(225, 225, 240), Enum.TextXAlignment.Left)
	-- reward tiles
	local tiles = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = O(412, 96), Size = O(200, 66), BackgroundTransparency = 1 }, c)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6) }, tiles)
	for i, name in ipairs(def.Rewards or {}) do
		local t = new("Frame", { LayoutOrder = i, Size = O(60, 60), BackgroundColor3 = def.Color:Lerp(WHITE, 0.15) }, tiles)
		corner(t, 10) border(t, INK, 3) gloss(t, WHITE, Color3.fromRGB(120, 120, 150))
		icon(name, { Position = O(6, 6), Size = O(48, 48) }, t)
	end
	-- bottom strip
	local strip = new("Frame", { Position = O(0, 176), Size = O(426, 48), BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, c)
	local chip = new("Frame", { Position = O(14, 8), Size = O(220, 32), BackgroundColor3 = INK, BackgroundTransparency = 0.25 }, strip)
	corner(chip, 8)
	refs.Chip = label(chip, { Position = O(10, 4), Size = O(200, 24) }, 19, WHITE, Enum.TextXAlignment.Left)
	refs.ChipFrame = chip
	label(strip, { Position = O(240, 10), Size = O(150, 28), Text = def.Soon and "Coming soon" or "Click to view" }, 21, WHITE, Enum.TextXAlignment.Right)
	icon(def.Soon and "lock" or "play", { Position = O(394, 12), Size = O(24, 24) }, strip)
	if def.Soon then
		local shade = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.5, ZIndex = 3 }, c)
		local lockTag = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = O(213, 100), Size = O(240, 50), BackgroundColor3 = Color3.fromRGB(40, 40, 60), ZIndex = 4 }, c)
		corner(lockTag, 25) border(lockTag, INK, 3)
		label(lockTag, { Position = O(10, 6), Size = O(220, 38), Text = "COMING SOON", ZIndex = 5 }, 28, GOLD)
	end
	c.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1.025 }):Play() end)
	c.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	c.MouseButton1Click:Connect(function()
		if def.Soon then toast(def.Title .. " is coming in a future update!") return end
		if def.OnClick then def.OnClick() end
	end)
	cardRefs[def.Id] = refs
	return c
end

---------------------------------------------------------------- detail view
local detail = new("Frame", { Position = O(684, 24), Size = O(900, 772), BackgroundTransparency = 1, Visible = false }, canvas)
local backToModes = button(detail, { Position = O(0, 0), Size = O(150, 50) }, "< Modes", GREY, 22)
local dTitle = label(detail, { Position = O(170, -4), Size = O(700, 56) }, 50, WHITE, Enum.TextXAlignment.Left)
local dSub = label(detail, { Position = O(172, 50), Size = O(700, 26) }, 21, LILAC, Enum.TextXAlignment.Left)
local dBody = new("Frame", { Position = O(0, 92), Size = O(890, 560), BackgroundTransparency = 1 }, detail)
local startBtn, startText = button(detail, { Position = O(560, 676), Size = O(320, 86) }, "START", GREEN, 40)
local startNote = label(detail, { Position = O(0, 684), Size = O(540, 70) }, 21, LILAC, Enum.TextXAlignment.Left, BOLD)
startNote.TextWrapped = true

local function statTile(parent, x, title, value, color)
	local t = new("Frame", { Position = O(x, 0), Size = O(280, 120), BackgroundColor3 = Color3.fromRGB(26, 28, 72) }, parent)
	corner(t, 14) border(t, INK, 3)
	local bar = new("Frame", { Size = O(280, 8), BackgroundColor3 = color, BorderSizePixel = 0 }, t)
	corner(bar, 4)
	label(t, { Position = O(16, 18), Size = O(250, 26), Text = title }, 20, color:Lerp(WHITE, 0.3), Enum.TextXAlignment.Left)
	label(t, { Position = O(16, 48), Size = O(250, 56), Text = value }, 46, WHITE, Enum.TextXAlignment.Left)
end
local function bodyText(parent, y, h, text)
	local l = label(parent, { Position = O(4, y), Size = O(880, h), Text = text, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top }, 24, WHITE, Enum.TextXAlignment.Left, BOLD)
	return l
end
local function rewardLine(parent, y, iconName, text, color)
	local f = new("Frame", { Position = O(0, y), Size = O(880, 58), BackgroundColor3 = Color3.fromRGB(26, 28, 72) }, parent)
	corner(f, 12) border(f, INK, 3)
	local tile = new("Frame", { Position = O(8, 6), Size = O(46, 46), BackgroundColor3 = color }, f)
	corner(tile, 10) border(tile, INK, 2) gloss(tile)
	icon(iconName, { Position = O(4, 4), Size = O(38, 38) }, tile)
	label(f, { Position = O(68, 12), Size = O(800, 34), Text = text }, 24, WHITE, Enum.TextXAlignment.Left)
end

local currentStart -- function that starts the selected mode
local function refreshStartButton()
	local p = state.party
	if p and p.Countdown then
		startText.Text = "STARTING " .. p.Countdown
		startBtn.BackgroundColor3 = GOLD
	elseif isLeader() then
		startText.Text = "START"
		startBtn.BackgroundColor3 = GREEN
	else
		startText.Text = "WAITING"
		startBtn.BackgroundColor3 = GREY
	end
	local n = #members()
	if isLeader() then
		startNote.Text = n > 1 and ("Everyone in your party (%d/4) joins this battle."):format(n) or "Playing solo. Invite friends with the + slots or Invite Players."
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

local showModes -- forward
local function openDetail(kind)
	state.detail = kind
	right.Visible = false
	detail.Visible = true
	dBody:ClearAllChildren()
	if kind == "Story" then
		dTitle.Text = "Story"
		dTitle.TextColor3 = Color3.fromRGB(110, 185, 255)
		dSub.Text = "Pick an act. Clear it to unlock the next one."
		local cleared = clearedActs()
		state.selectedAct = state.selectedAct or currentAct().Id
		local list = new("Frame", { Size = O(890, 560), BackgroundTransparency = 1 }, dBody)
		new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		local rows = {}
		local function paint()
			for id, r in pairs(rows) do r.Stroke.Color = (id == state.selectedAct) and GOLD or INK r.Stroke.Thickness = (id == state.selectedAct) and 5 or 3 end
		end
		for i, act in ipairs(Config.Stages.Story) do
			local locked = act.RequiresAct and not cleared[act.RequiresAct]
			local done = cleared[act.Id]
			local r = new("TextButton", { LayoutOrder = i, Size = O(880, 124), BackgroundColor3 = locked and Color3.fromRGB(40, 40, 58) or Color3.fromRGB(26, 34, 86), Text = "", AutoButtonColor = not locked }, list)
			corner(r, 14)
			local st = border(r, INK, 3)
			local strip = new("Frame", { Size = O(14, 124), BackgroundColor3 = locked and GREY or Color3.fromRGB(46, 140, 255), BorderSizePixel = 0 }, r)
			corner(strip, 7)
			label(r, { Position = O(32, 12), Size = O(560, 40), Text = act.Name }, 34, locked and Color3.fromRGB(170, 170, 185) or WHITE, Enum.TextXAlignment.Left)
			local drops = {}
			local md = Config.MaterialDrops and Config.MaterialDrops[act.Id]
			if md and md.Mats then for _, m in ipairs(md.Mats) do table.insert(drops, m[1]) end end
			label(r, { Position = O(34, 58), Size = O(620, 26), Text = ("+%d Gems  •  +%d XP%s"):format(act.RewardGems or 0, act.RewardXP or 0, #drops > 0 and ("  •  Drops: " .. table.concat(drops, ", ")) or "") }, 21, Color3.fromRGB(215, 220, 245), Enum.TextXAlignment.Left, BOLD)
			label(r, { Position = O(34, 88), Size = O(620, 24), Text = locked and ("Clear " .. tostring(act.RequiresAct) .. " to unlock") or ("Enemy HP x" .. tostring(act.HpScale or 1)) }, 19, locked and GOLD or LILAC, Enum.TextXAlignment.Left, BOLD)
			local chip = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = O(860, 62), Size = O(150, 44), BackgroundColor3 = locked and GREY or (done and GREEN or GOLD) }, r)
			corner(chip, 22) border(chip, INK, 3)
			label(chip, { Position = O(8, 6), Size = O(134, 32), Text = locked and "LOCKED" or (done and "CLEARED" or "NEW") }, 24, done and WHITE or INK)
			rows[act.Id] = { Stroke = st }
			r.MouseButton1Click:Connect(function()
				if locked then toast("Clear " .. tostring(act.RequiresAct) .. " first!") return end
				state.selectedAct = act.Id
				paint()
			end)
		end
		paint()
		currentStart = function() launch("Story", state.selectedAct) end
	elseif kind == "Infinite" then
		dTitle.Text = "Infinite"
		dTitle.TextColor3 = Color3.fromRGB(190, 150, 255)
		dSub.Text = "Competitive  •  endless waves"
		statTile(dBody, 0, "YOUR BEST WAVE", tostring(player:GetAttribute("BestInfiniteWave") or 0), Color3.fromRGB(150, 90, 255))
		statTile(dBody, 300, "LEADERBOARD", "Top Waves", GOLD)
		bodyText(dBody, 150, 110, "The waves never stop and every wave hits harder. Survive as long as you can - your best wave goes on the Top Waves board.")
		rewardLine(dBody, 280, "gems", "Gems and XP that grow with every wave you survive", Color3.fromRGB(80, 170, 255))
		rewardLine(dBody, 350, "topwaves", "A spot on the Top Waves leaderboard", GOLD)
		currentStart = function() launch("Infinite") end
	elseif kind == "Aegis" then
		local mod = aegisMod()
		dTitle.Text = "Aegis Mode"
		dTitle.TextColor3 = Color3.fromRGB(90, 235, 220)
		dSub.Text = "Special  •  defend the Aegis core"
		statTile(dBody, 0, "YOUR BEST WAVE", tostring(player:GetAttribute("BestAegisWave") or 0), Color3.fromRGB(30, 200, 190))
		statTile(dBody, 300, "THIS WEEK", mod.Name or "?", GOLD)
		local desc = mod.Description or mod.Desc or ""
		bodyText(dBody, 150, 110, "Protect the Aegis core with your team and buy core upgrades between waves." .. (desc ~= "" and ("  This week: " .. desc) or ""))
		rewardLine(dBody, 280, "shards", "Aegis Shards for the Shard Shop", Color3.fromRGB(40, 220, 200))
		rewardLine(dBody, 350, "evolve", "Hero Emblem - evolution item, only drops here", Color3.fromRGB(255, 150, 60))
		rewardLine(dBody, 420, "crystal", "Very rare: an Aegis unit (from wave 10)", Color3.fromRGB(80, 230, 255))
		currentStart = function() launch("Aegis") end
	end
	refreshStartButton()
end

showModes = function()
	state.detail = nil
	detail.Visible = false
	right.Visible = true
	local cleared = clearedActs()
	local n, total = 0, #Config.Stages.Story
	for _, a in ipairs(Config.Stages.Story) do if cleared[a.Id] then n += 1 end end
	local cur = currentAct()
	local s = cardRefs.Story
	s.Label1.Text = "Current Map"
	s.Value1.Text = n >= total and "All acts cleared!" or actMapName(cur)
	s.Value2.Text = ("%d/%d Acts Cleared"):format(n, total)
	s.Chip.Text = ("Total Progress: %d%%"):format(math.floor(n / total * 100 + 0.5))
	local a = cardRefs.Aegis
	a.Label1.Text = "Weekly Modifier"
	a.Value1.Text = aegisMod().Name or "?"
	a.Value2.Text = "Rare Aegis unit drops!"
	a.Chip.Text = ("Best Wave: %d"):format(player:GetAttribute("BestAegisWave") or 0)
	local inf = cardRefs.Infinite
	inf.Label1.Text = "Endless Waves"
	inf.Value1.Text = "Top Waves Board"
	inf.Value2.Text = "How far can you go?"
	inf.Chip.Text = ("Best Wave: %d"):format(player:GetAttribute("BestInfiniteWave") or 0)
	for _, id in ipairs({ "Raid", "BossRush", "Challenge" }) do
		local r = cardRefs[id]
		r.Label1.Text = "Coming Soon"
		r.Value1.Text = "Future update"
		r.Value2.Text = ""
		r.ChipFrame.Visible = false
	end
end
backToModes.MouseButton1Click:Connect(showModes)

-- build the sections (same layout as the reference: ribbon + rows of cards)
ribbon("Progressive", Color3.fromRGB(40, 150, 255))
local r1 = row()
card(r1, { Id = "Story", Order = 1, Title = "Story", Sub = "Progressive Gamemode", Color = Color3.fromRGB(46, 140, 255), Icon = "play",
	Rewards = { "gems", "crystal", "evolve" }, OnClick = function() openDetail("Story") end })
card(r1, { Id = "Raid", Order = 2, Title = "Raid", Sub = "Difficult Gamemode", Color = Color3.fromRGB(230, 60, 60), Icon = "damage", Soon = true })
ribbon("Special", Color3.fromRGB(30, 200, 190))
local r2 = row()
card(r2, { Id = "Aegis", Order = 1, Title = "Aegis Mode", Sub = "Special Gamemode", Color = Color3.fromRGB(30, 200, 190), Icon = "shards",
	Rewards = { "shards", "evolve", "crystal" }, OnClick = function() openDetail("Aegis") end })
card(r2, { Id = "BossRush", Order = 2, Title = "Boss Rush", Sub = "Special Gamemode", Color = Color3.fromRGB(215, 50, 190), Icon = "events", Soon = true })
ribbon("Competitive", Color3.fromRGB(255, 160, 40))
local r3 = row()
card(r3, { Id = "Infinite", Order = 1, Title = "Infinite", Sub = "Competitive Gamemode", Color = Color3.fromRGB(150, 90, 255), Icon = "topwaves",
	Rewards = { "gems", "topwaves" }, OnClick = function() openDetail("Infinite") end })
card(r3, { Id = "Challenge", Order = 2, Title = "Challenge", Sub = "Reward Gamemode", Color = Color3.fromRGB(255, 160, 40), Icon = "quests", Soon = true })

---------------------------------------------------------------- countdown banner
local banner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = O(1134, -4), Size = O(620, 60), BackgroundColor3 = GOLD, Visible = false, ZIndex = 5 }, canvas)
corner(banner, 16) border(banner, INK, 4) gloss(banner)
local bannerText = label(banner, { Position = O(16, 8), Size = O(430, 44), ZIndex = 6 }, 28, INK, Enum.TextXAlignment.Left)
local cancelBtn = button(banner, { Position = O(470, 8), Size = O(136, 44), ZIndex = 6 }, "Cancel", RED, 22)
cancelBtn.MouseButton1Click:Connect(function() PartyRemote:InvokeServer("Cancel") end)
local function refreshBanner()
	local p = state.party
	banner.Visible = p ~= nil and p.Countdown ~= nil
	if banner.Visible then
		bannerText.Text = ("%s in %d..."):format(p.Label, p.Countdown)
		cancelBtn.Visible = isLeader()
	end
end

---------------------------------------------------------------- bottom bar
local bar = new("Frame", { Position = O(-200, 812), Size = O(W + 400, 100), BackgroundColor3 = INK, BackgroundTransparency = 0.25, BorderSizePixel = 0 }, canvas)
local backBtn = button(bar, { Position = O(232, 16), Size = O(250, 66) }, "Back", GREY, 30)
local inviteBtn = button(bar, { Position = O(1296, 16), Size = O(250, 66) }, "Invite Players", GREY, 28)
local joinBtn, joinText = button(bar, { Position = O(1562, 16), Size = O(250, 66) }, "Join Party", PURPLE, 28)
local function refreshBar()
	local inOthers = state.party and state.party.Host ~= player.UserId
	joinText.Text = inOthers and "Leave Party" or "Join Party"
	joinBtn.BackgroundColor3 = inOthers and RED or PURPLE
	inviteBtn.Visible = isLeader()
end

---------------------------------------------------------------- popups (invite list / join list)
local shade = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 20 }, root)
local modal = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = O(640, 600), BackgroundColor3 = Color3.fromRGB(20, 22, 62), ZIndex = 21, Active = true }, shade)
corner(modal, 20) border(modal, INK, 5)
table.insert(scales, new("UIScale", {}, modal))
local mTitle = label(modal, { Position = O(24, 16), Size = O(480, 48), ZIndex = 22 }, 38, WHITE, Enum.TextXAlignment.Left)
local mClose = button(modal, { Position = O(572, 16), Size = O(50, 50), ZIndex = 22 }, "X", RED, 26)
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

local openList -- forward
local function listRow(i, uid, name, sub, btnText, btnColor, onClick)
	local r = new("Frame", { Position = O(0, (i - 1) * 84), Size = O(580, 72), BackgroundColor3 = Color3.fromRGB(30, 34, 86), ZIndex = 23 }, mList)
	corner(r, 14) border(r, INK, 3)
	headshot(r, uid, 24)
	label(r, { Position = O(80, 8), Size = O(300, 32), Text = name, ZIndex = 24 }, 26, WHITE, Enum.TextXAlignment.Left)
	label(r, { Position = O(80, 40), Size = O(300, 22), Text = sub, ZIndex = 24 }, 18, LILAC, Enum.TextXAlignment.Left, BOLD)
	local b = button(r, { Position = O(408, 12), Size = O(160, 48), ZIndex = 24 }, btnText, btnColor, 22)
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 25 end end
	if onClick then b.MouseButton1Click:Connect(function() onClick(b) end) else b.AutoButtonColor = false end
end

openList = function(kind)
	for _, c in ipairs(mList:GetChildren()) do c:Destroy() end
	shade.Visible = true
	mEmpty.Text = "Loading..."
	if kind == "Invite" then
		mTitle.Text = "Invite Players"
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
		mTitle.Text = "Join a Party"
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
local inviteCard = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 96), Size = O(440, 150), BackgroundColor3 = Color3.fromRGB(20, 22, 62), Visible = false, ZIndex = 40 }, gui)
corner(inviteCard, 18) border(inviteCard, GOLD, 4)
table.insert(scales, new("UIScale", {}, inviteCard))
local invTitle = label(inviteCard, { Position = O(18, 12), Size = O(404, 34), ZIndex = 41 }, 28, WHITE, Enum.TextXAlignment.Left)
local invSub = label(inviteCard, { Position = O(18, 48), Size = O(404, 24), ZIndex = 41 }, 20, LILAC, Enum.TextXAlignment.Left, BOLD)
local invJoin = button(inviteCard, { Position = O(18, 86), Size = O(196, 50), ZIndex = 41 }, "Join", GREEN, 24)
local invNo = button(inviteCard, { Position = O(226, 86), Size = O(196, 50), ZIndex = 41 }, "Decline", GREY, 24)
for _, d in ipairs(inviteCard:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 41) end end
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
	invTitle.Text = info.Name .. " invited you!"
	invSub.Text = info.Label or ""
	inviteCard.Visible = true
	inviteId += 1
	local id = inviteId
	task.delay(15, function() if inviteId == id then inviteCard.Visible = false end end)
end)

---------------------------------------------------------------- wiring
local function refreshAll()
	refreshParty()
	refreshBar()
	refreshBanner()
	if state.detail then refreshStartButton() end
end
PartyUpdate.OnClientEvent:Connect(function(snap)
	local had = state.party
	state.party = snap
	if not snap and root.Visible and player:GetAttribute("InMatch") ~= true then
		-- left / kicked / launched: get your own party of 1 back
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
		showModes()
		shownKey = "" -- re-clone characters (outfits may have changed)
		task.spawn(function()
			local ok, s = PartyRemote:InvokeServer("Open")
			if ok then state.party = s end
			refreshAll()
		end)
		refreshAll()
	else
		closeModal()
	end
end
root:GetPropertyChangedSignal("Visible"):Connect(onVisible)
player:GetAttributeChangedSignal("InMatch"):Connect(function()
	if player:GetAttribute("InMatch") then root.Visible = false inviteCard.Visible = false end
end)
fit()
showModes()
refreshAll()
