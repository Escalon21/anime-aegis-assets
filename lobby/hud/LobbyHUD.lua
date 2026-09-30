----------------------------------------------------------------- lobby layer (hidden during battles)  -- HUD v4 (matches Omar's Claude Design "Lobby HUD" 1:1)
local layer = new("Frame", { Name = "LobbyLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)

local DARK = Color3.fromRGB(30, 34, 51)
local CHIP = Color3.fromRGB(26, 29, 43)
local CHIPEDGE = Color3.fromRGB(62, 67, 92)
local LIGHT = Color3.fromRGB(230, 230, 240)
local EDGE = Color3.fromRGB(216, 216, 230)
local GOLD = Color3.fromRGB(245, 184, 58)
local TEAL = Color3.fromRGB(53, 235, 192)
local LIVE = Color3.fromRGB(232, 65, 60)
local K = 0.72 -- design px (2000 wide mock) -> HUD px (fitScale then fits the screen)
local function P(v) return math.floor(v * K + 0.5) end
local TH, CH = 3, P(16)

local function fmt(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
local function lab(parent, props, size, color, align, font)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = font or Enum.Font.GothamBold, TextColor3 = color or WHITE, TextScaled = true,
		Text = "", TextXAlignment = align or Enum.TextXAlignment.Center }, parent)
	for k, v in pairs(props) do l[k] = v end
	new("UITextSizeConstraint", { MaxTextSize = size }, l)
	return l
end

-- a solid box with its bottom-right corner cut off at 45 degrees
local function chamfer(parent, x, y, w, h, c, color, z)
	c = math.max(2, math.min(c, w, h))
	local box = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, ZIndex = z }, parent)
	new("Frame", { Size = UDim2.fromOffset(w, h - c), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z }, box)
	new("Frame", { Position = UDim2.fromOffset(0, h - c), Size = UDim2.fromOffset(w - c, c), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z }, box)
	local tri = new("Frame", { Position = UDim2.fromOffset(w - c, h - c), Size = UDim2.fromOffset(c, c), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z }, box)
	new("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.499, 0),
		NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) }) }, tri)
	return box
end
-- border + fill, both chamfered
local function plate(parent, x, y, w, h, edge, fill, z)
	chamfer(parent, x, y, w, h, CH, edge, z)
	return chamfer(parent, x + TH, y + TH, w - 2 * TH, h - 2 * TH, CH - 0.586 * TH, fill, z + 1)
end

-- icons: sprite sheet when it has the icon (tinted), otherwise an emoji
local GLYPH = { units = "⭐", items = "🎒", quests = "📜", summon = "✨", bonds = "🔗", play = "🚀", shop = "🏪", events = "🔥",
	topwaves = "📊", profile = "🪪", pass = "🎖️", daily = "📅", trophy = "🏆", upd = "📣", gear = "⚙️" }
local function icon(parent, name, pos, size, tint, z)
	local img = Icons.New(name, { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), ImageColor3 = tint or WHITE, ZIndex = z }, parent)
	if img then return img end
	return new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1,
		Text = GLYPH[name] or "?", TextScaled = true, Font = Enum.Font.GothamBold, TextColor3 = tint or WHITE, ZIndex = z }, parent)
end
local function circleIcon(parent, name, pos, d, color, z)
	local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(d, d), BackgroundColor3 = color, ZIndex = z }, parent)
	corner(c, d)
	icon(c, name, UDim2.fromScale(0.5, 0.5), math.floor(d * 0.6), DARK, z + 1)
	return c
end
local function keyBadge(parent, key, color, z)
	local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(P(27), P(27)), Rotation = 45,
		BackgroundColor3 = DARK, BorderSizePixel = 0, ZIndex = z }, parent)
	new("UIStroke", { Color = color, Thickness = 2 }, d)
	lab(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(16, 14), Text = key, ZIndex = z + 1 }, 13)
end
local function dotBadge(parent, text, color, z)
	local b = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 2), Size = UDim2.fromOffset(P(28), P(28)), BackgroundColor3 = color,
		Text = text, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = WHITE, ZIndex = z }, parent)
	corner(b, 20)
	new("UIStroke", { Color = DARK, Thickness = 2 }, b)
	new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, b)
	return b
end
local function hover(b)
	local s = new("UIScale", {}, b)
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1.06 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	b.MouseButton1Down:Connect(function() TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.95 }):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(s, TweenInfo.new(0.1), { Scale = 1.06 }):Play() end)
end

-- tiles. kinds: "light" (light top + coloured icon circle + dark label bar), "shop" (light icon square + dark label),
-- "dark" (dark tile, bare icon, label underneath)
local function hudTile(parent, x, y, w, h, o)
	local b = new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
	plate(b, 0, 0, w, h, o.edge, o.fill, 1)
	local ci = CH - 0.586 * TH
	if o.kind == "shop" then
		local sq = h - 2 * TH
		new("Frame", { Position = UDim2.fromOffset(TH, TH), Size = UDim2.fromOffset(sq, sq), BackgroundColor3 = LIGHT, BorderSizePixel = 0, ZIndex = 3 }, b)
		new("Frame", { Position = UDim2.fromOffset(TH + sq, TH), Size = UDim2.fromOffset(2, sq), BackgroundColor3 = o.edge, BorderSizePixel = 0, ZIndex = 3 }, b)
		icon(b, o.icon, UDim2.fromOffset(TH + sq / 2, h / 2), math.floor(sq * 0.6), DARK, 4)
		lab(b, { Position = UDim2.fromOffset(TH + sq + 6, h * 0.22), Size = UDim2.fromOffset(w - 2 * TH - sq - 10, h * 0.56), Text = o.text, ZIndex = 4 }, P(34), WHITE, Enum.TextXAlignment.Left)
	elseif o.kind == "dark" then
		icon(b, o.icon, UDim2.fromOffset(w / 2, h * 0.42), math.floor(h * 0.4), o.iconColor, 4)
		lab(b, { Position = UDim2.fromOffset(4, h - TH - P(38)), Size = UDim2.fromOffset(w - 8, P(26)), Text = o.text, ZIndex = 4 }, P(24))
	else
		local lb = P(40)
		chamfer(b, TH, h - TH - lb, w - 2 * TH, lb, ci, o.bar or DARK, 3)
		lab(b, { Position = UDim2.fromOffset(TH + 4, h - TH - lb + lb * 0.16), Size = UDim2.fromOffset(w - 2 * TH - 8, lb * 0.68), Text = o.text, ZIndex = 4 },
			P(28), o.labelColor or WHITE)
		local cy = TH + (h - 2 * TH - lb) / 2
		if o.bare then
			icon(b, o.icon, UDim2.fromOffset(w / 2, cy), math.floor((h - 2 * TH - lb) * 0.66), o.iconColor, 4)
		else
			circleIcon(b, o.icon, UDim2.fromOffset(w / 2, cy), P(56), o.edge, 4)
		end
	end
	if o.key then keyBadge(b, o.key, o.edge, 8) end
	hover(b)
	return b
end

-- LEFT: Aegis Shop, 2x3 grid, Events
local SQ, G = P(118), P(15)
local W = SQ * 2 + G
local left = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, P(24), 0.5, 0), Size = UDim2.fromOffset(W, P(606)) }, layer)
fitScale(left)
local ROW = { P(92), P(224), P(356) }
local function lightTile(col, row, text, iconName, color, key)
	return hudTile(left, col * (SQ + G), ROW[row], SQ, SQ, { kind = "light", text = text, icon = iconName, edge = color, fill = LIGHT, key = key })
end
local shopBtn = hudTile(left, 0, 0, W, P(77), { kind = "shop", text = "Aegis Shop", icon = "shop", edge = Color3.fromRGB(255, 63, 164), fill = DARK })
local unitsBtn = lightTile(0, 1, "Units", "units", Color3.fromRGB(245, 166, 35), "H")
local itemsBtn = lightTile(1, 1, "Items", "items", TEAL, "J")
local questsBtn = lightTile(0, 2, "Quests", "quests", Color3.fromRGB(232, 65, 60), "K")
local summonBtn = lightTile(1, 2, "Summon", "summon", Color3.fromRGB(155, 140, 224), "G")
local bondsBtn = lightTile(0, 3, "Bonds", "bonds", Color3.fromRGB(255, 79, 168))
local playBtn = hudTile(left, SQ + G, ROW[3], SQ, SQ, { kind = "light", text = "PLAY", icon = "play", edge = TEAL, fill = DARK, bar = TEAL,
	labelColor = DARK, bare = true, iconColor = TEAL })
local eventsBtn = hudTile(left, 0, P(489), W, P(117), { kind = "light", text = "Events", icon = "events", edge = Color3.fromRGB(245, 176, 58), fill = LIGHT })
local liveTag = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, P(10), 0, 0), Size = UDim2.fromOffset(P(50), P(24)), BackgroundColor3 = LIVE,
	BorderSizePixel = 0, Text = "LIVE", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = WHITE, ZIndex = 9 }, eventsBtn)
new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, liveTag)
new("UIStroke", { Color = DARK, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, liveTag)
local questBadge = dotBadge(questsBtn, "3", Color3.fromRGB(255, 63, 164), 9)
questBadge.Visible = false

-- PLAY breathes a little so it reads as the main button
task.spawn(function()
	local s = playBtn:FindFirstChildOfClass("UIScale")
	while playBtn.Parent do
		if s and s.Scale == 1 then
			TweenService:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { Scale = 1.03 }):Play() task.wait(0.7)
			if s.Scale > 1.02 and s.Scale < 1.04 then TweenService:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { Scale = 1 }):Play() end
			task.wait(0.9)
		else
			task.wait(0.5)
		end
	end
end)

unitsBtn.MouseButton1Click:Connect(function() togglePanel("Units") end)
summonBtn.MouseButton1Click:Connect(function() togglePanel("Summon") end)
questsBtn.MouseButton1Click:Connect(function() togglePanel("Quests") end)
shopBtn.MouseButton1Click:Connect(function() togglePanel("AegisShop") end)
itemsBtn.MouseButton1Click:Connect(function() togglePanel("Items") end)
bondsBtn.MouseButton1Click:Connect(function() togglePanel("Bonds") end)
eventsBtn.MouseButton1Click:Connect(function() togglePanel("Events") end)

task.spawn(function()
	local qg = playerGui:WaitForChild("QuestGui", 20)
	if not qg then return end
	local function sync()
		local n = qg:GetAttribute("ClaimableCount")
		questBadge.Text = n and tostring(n) or "!"
		questBadge.Visible = qg:GetAttribute("Claimable") == true
	end
	qg:GetAttributeChangedSignal("Claimable"):Connect(sync)
	qg:GetAttributeChangedSignal("ClaimableCount"):Connect(sync)
	sync()
end)

-- RIGHT: Aegis Pass, Top Waves, Profile, Daily (one narrow column)
local RW = P(122)
local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -P(25), 0.5, 0), Size = UDim2.fromOffset(RW, P(526)) }, layer)
fitScale(right)
local passBtn = new("TextButton", { Size = UDim2.fromOffset(RW, P(143)), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, right)
plate(passBtn, 0, 0, RW, P(143), Color3.fromRGB(128, 112, 208), DARK, 1)
lab(passBtn, { Position = UDim2.fromOffset(4, P(10)), Size = UDim2.fromOffset(RW - 8, P(18)), Text = "LVL 0/50", ZIndex = 4 }, P(20), Color3.fromRGB(200, 200, 220))
icon(passBtn, "pass", UDim2.fromOffset(RW / 2, P(62)), P(48), Color3.fromRGB(155, 140, 224), 4)
lab(passBtn, { Position = UDim2.fromOffset(4, P(94)), Size = UDim2.fromOffset(RW - 8, P(24)), Text = "Aegis Pass", ZIndex = 4 }, P(26))
lab(passBtn, { Position = UDim2.fromOffset(4, P(119)), Size = UDim2.fromOffset(RW - 8, P(15)), Text = "Season 1", ZIndex = 4 }, P(17), Color3.fromRGB(184, 184, 208), nil, Enum.Font.GothamMedium)
hover(passBtn)
passBtn.MouseButton1Click:Connect(function() showToast("The Aegis Pass arrives with Season 1 - coming soon!") end)

local function darkTile(y, text, iconName, iconColor)
	return hudTile(right, 0, y, RW, P(113), { kind = "dark", text = text, icon = iconName, edge = EDGE, fill = DARK, iconColor = iconColor })
end
local topBtn = darkTile(P(158), "Top Waves", "topwaves", TEAL)
local profileBtn = darkTile(P(286), "Profile", "profile", Color3.fromRGB(216, 216, 230))
local dailyBtn = darkTile(P(414), "Daily", "daily", GOLD)
dotBadge(dailyBtn, "!", LIVE, 9).Position = UDim2.new(1, -2, 0, 4)
topBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
profileBtn.MouseButton1Click:Connect(function() togglePanel("Profile") end)
dailyBtn.MouseButton1Click:Connect(function() showToast("Daily rewards are coming soon!") end)

-- TOP RIGHT: trophy | UPD chip
local CW, CHh = P(200), P(51)
local chip = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -P(25), 0, P(22)), Size = UDim2.fromOffset(CW, CHh), BackgroundTransparency = 1 }, layer)
fitScale(chip)
chamfer(chip, 0, 0, CW, CHh, P(12), CHIPEDGE, 1)
chamfer(chip, 2, 2, CW - 4, CHh - 4, P(12) - 1, CHIP, 2)
local trophyBtn = new("TextButton", { Size = UDim2.fromOffset(P(62), CHh), BackgroundTransparency = 1, Text = "", ZIndex = 3 }, chip)
icon(trophyBtn, "trophy", UDim2.fromOffset(P(33), CHh / 2), P(30), GOLD, 4)
new("Frame", { Position = UDim2.fromOffset(P(62), CHh * 0.25), Size = UDim2.fromOffset(2, CHh * 0.5), BackgroundColor3 = CHIPEDGE, BorderSizePixel = 0, ZIndex = 3 }, chip)
local updBtn = new("TextButton", { Position = UDim2.fromOffset(P(66), 0), Size = UDim2.fromOffset(CW - P(66), CHh), BackgroundTransparency = 1, Text = "", ZIndex = 3 }, chip)
icon(updBtn, "upd", UDim2.fromOffset(P(26), CHh / 2), P(30), TEAL, 4)
lab(updBtn, { Position = UDim2.fromOffset(P(48), CHh * 0.24), Size = UDim2.fromOffset(P(80), CHh * 0.52), Text = "UPD 1", ZIndex = 4 }, P(28), WHITE, Enum.TextXAlignment.Left)
hover(trophyBtn) hover(updBtn)
trophyBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
updBtn.MouseButton1Click:Connect(function() togglePanel("Updates") end)

-- BOTTOM: gems / coins / settings, team, XP bar
local BW = P(861)
local bottom = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -P(26)), Size = UDim2.fromOffset(BW, P(251)) }, layer)
fitScale(bottom)
local pillRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, P(55)) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, P(16)), SortOrder = Enum.SortOrder.LayoutOrder }, pillRow)
local function chipBox(order, w, class)
	local h = P(55)
	local f = new(class or "Frame", { LayoutOrder = order, Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1 }, pillRow)
	if class == "TextButton" then f.Text = "" f.AutoButtonColor = false end
	chamfer(f, 0, 0, w, h, P(12), CHIPEDGE, 1)
	chamfer(f, 2, 2, w - 4, h - 4, P(12) - 1, CHIP, 2)
	return f, h
end
local gemP, ph = chipBox(1, P(154))
local gem = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(P(28), ph / 2), Size = UDim2.fromOffset(P(30), P(30)), Rotation = 45,
	BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, gemP)
new("UIGradient", { Rotation = -45, Color = ColorSequence.new(TEAL, Color3.fromRGB(150, 120, 230)) }, gem)
new("UIStroke", { Color = TEAL, Thickness = 2 }, gem)
local gemsL = lab(gemP, { Position = UDim2.fromOffset(P(54), ph * 0.2), Size = UDim2.fromOffset(P(154) - P(62), ph * 0.6), ZIndex = 3 }, P(38), WHITE, Enum.TextXAlignment.Left)
local coinP = chipBox(2, P(180))
local coin = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(P(32), ph / 2), Size = UDim2.fromOffset(P(36), P(36)), BackgroundColor3 = GOLD, ZIndex = 3 }, coinP)
corner(coin, 20)
new("UIStroke", { Color = Color3.fromRGB(200, 130, 30), Thickness = 2 }, coin)
lab(coin, { Size = UDim2.fromScale(1, 1), Text = "¥", ZIndex = 4 }, 14, Color3.fromRGB(120, 70, 10))
local coinsL = lab(coinP, { Position = UDim2.fromOffset(P(60), ph * 0.2), Size = UDim2.fromOffset(P(180) - P(68), ph * 0.6), ZIndex = 3 }, P(38), GOLD, Enum.TextXAlignment.Left)
local gearBtn = chipBox(3, P(56), "TextButton")
icon(gearBtn, "gear", UDim2.fromOffset(P(28), ph / 2), P(30), Color3.fromRGB(216, 216, 230), 3)
hover(gearBtn)
gearBtn.MouseButton1Click:Connect(function() showToast("Settings are coming soon!") end)

-- team cards
local CARD_W, CARD_H = P(120), P(137)
local team = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, P(62)), Size = UDim2.new(1, 0, 0, P(152)) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, P(21)), SortOrder = Enum.SortOrder.LayoutOrder }, team)
local RARITY_PIPS = { Rare = 1, Epic = 2, Legendary = 3, Mythic = 4, Secret = 5 }
local cards = {}
for i = 1, 6 do
	local c = new("TextButton", { LayoutOrder = i, Size = UDim2.fromOffset(CARD_W, P(152)), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, team)
	local top = P(13)
	new("Frame", { Position = UDim2.fromOffset(4, top + 4), Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundColor3 = Color3.fromRGB(14, 15, 24), BorderSizePixel = 0 }, c) -- shadow
	local body = new("Frame", { Position = UDim2.fromOffset(0, top), Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundColor3 = DARK, BorderSizePixel = 0, ZIndex = 2 }, c)
	local st = new("UIStroke", { Color = CHIPEDGE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, body)
	local ART_H = P(97)
	local art = new("CanvasGroup", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(CARD_W - 6, ART_H), BackgroundColor3 = Color3.fromRGB(90, 90, 120), BorderSizePixel = 0, ZIndex = 3 }, body)
	for k = -4, 8 do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(k * 13, ART_H / 2), Size = UDim2.fromOffset(5, 180),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.88, BorderSizePixel = 0, Rotation = 40 }, art)
	end
	local artL = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.8), Text = "unit art", Font = Enum.Font.Code, TextSize = 11,
		TextColor3 = DARK, TextTransparency = 0.35 }, art)
	local unitIcon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromOffset(ART_H * 0.7, ART_H * 0.7), BackgroundTransparency = 1, Visible = false }, art)
	local pips = new("Frame", { Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1 }, art)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, pips)
	local pipList = {}
	for k = 1, 5 do
		local holder = new("Frame", { LayoutOrder = k, Size = UDim2.fromOffset(11, 11), BackgroundTransparency = 1 }, pips)
		local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0 }, holder)
		new("UIStroke", { Color = DARK, Thickness = 1.5 }, d)
		pipList[k] = holder
	end
	local cost = lab(body, { Position = UDim2.fromOffset(4, ART_H + 6), Size = UDim2.fromOffset(CARD_W - 8, CARD_H - ART_H - 12), ZIndex = 3 }, P(30), GOLD)
	local plus = lab(body, { Size = UDim2.fromScale(1, 1), Text = "+", ZIndex = 3 }, 34, Color3.fromRGB(110, 116, 150))
	local lvl = new("Frame", { Position = UDim2.fromOffset(P(8), 0), Size = UDim2.fromOffset(P(58), P(22)), BackgroundColor3 = Color3.fromRGB(21, 22, 32), BorderSizePixel = 0, ZIndex = 5 }, c)
	local lvlL = lab(lvl, { Position = UDim2.fromOffset(3, 2), Size = UDim2.new(1, -6, 1, -4), ZIndex = 5 }, P(22))
	local slot = new("Frame", { Position = UDim2.fromOffset(CARD_W - P(30), 0), Size = UDim2.fromOffset(P(22), P(22)), BackgroundColor3 = LIGHT, BorderSizePixel = 0, ZIndex = 5 }, c)
	lab(slot, { Position = UDim2.fromOffset(1, 2), Size = UDim2.new(1, -2, 1, -4), Text = tostring(i), ZIndex = 5 }, P(22), DARK)
	hover(c)
	c.MouseButton1Click:Connect(function() togglePanel("Units") end)
	cards[i] = { Card = body, Stroke = st, Art = art, ArtL = artL, Icon = unitIcon, Lvl = lvl, LvlL = lvlL, Pips = pips, PipList = pipList, Cost = cost, Plus = plus }
end

-- XP bar: teal fill, divider every 10%, text on top
local XH = P(26)
local xpBg = new("Frame", { Position = UDim2.fromOffset(0, P(225)), Size = UDim2.fromOffset(BW, XH), BackgroundColor3 = CHIP, BorderSizePixel = 0 }, bottom)
new("UIStroke", { Color = CHIPEDGE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, xpBg)
local xpBar = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = TEAL, BorderSizePixel = 0, ZIndex = 2 }, xpBg)
for k = 1, 9 do
	new("Frame", { Position = UDim2.new(k / 10, -1, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = CHIP, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3 }, xpBg)
end
local xpText = lab(xpBg, { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 1, -6), ZIndex = 4 }, P(24), WHITE)
new("UIStroke", { Color = DARK, Thickness = 1.5 }, xpText)

local function decodeAttr(a, fallback)
	local ok, v = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(a) or "")
	return (ok and type(v) == "table") and v or fallback
end
local function updateBottom()
	gemsL.Text = fmt(player:GetAttribute("Gems") or 0)
	coinsL.Text = fmt(player:GetAttribute("AegisShards") or 0)
	local inv = decodeAttr("Inventory", {})
	local eqU = decodeAttr("EquippedUids", {})
	local byUid = {}
	for _, u in ipairs(inv) do if type(u) == "table" then byUid[u.Uid] = u end end
	for i = 1, 6 do
		local c = cards[i]
		local u = eqU[i] and byUid[eqU[i]]
		local def = u and Config.Units[u.Id]
		local filled = def ~= nil
		for _, o in ipairs({ c.Lvl, c.Art, c.Cost }) do o.Visible = filled end
		c.Plus.Visible = not filled
		c.Card.BackgroundTransparency = filled and 0 or 0.3
		if filled then
			local r = Config.Rarities[def.Rarity]
			local rc = (r and r.Color) or def.Color or PURPLE
			c.Art.BackgroundColor3 = rc
			c.Stroke.Color = rc:Lerp(Color3.new(0, 0, 0), 0.35)
			c.LvlL.Text = "Lvl " .. (u.Level or 1)
			local hasIcon = Icons.Apply(c.Icon, Icons.Unit[u.Id])
			c.Icon.Visible = hasIcon
			c.ArtL.Visible = not hasIcon
			c.Cost.Text = "¥" .. fmt(def.Cost or 0)
			local n = RARITY_PIPS[def.Rarity] or 1
			if u.Evolved then n += 1 end
			for k = 1, 5 do c.PipList[k].Visible = k <= math.min(n, 5) end
			local t = u.Trait and Config.GetTrait(u.Trait)
			c.PipList[1]:FindFirstChildOfClass("Frame").BackgroundColor3 = t and t.Color or WHITE
		else
			c.Stroke.Color = CHIPEDGE
		end
	end
	local level = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local need = level * 100
	local frac = math.clamp(xp / need, 0, 1)
	TweenService:Create(xpBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(frac, 1) }):Play()
	xpText.Text = ("Lvl %d · %s / %s XP"):format(level, fmt(xp), fmt(need))
end
for _, a in ipairs({ "Gems", "EquippedUids", "Inventory", "Level", "XP", "AegisShards" }) do
	player:GetAttributeChangedSignal(a):Connect(updateBottom)
end
updateBottom()
