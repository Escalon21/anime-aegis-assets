----------------------------------------------------------------- lobby layer (hidden during battles)  -- HUD v3 (user's Claude Design "Lobby HUD")
local layer = new("Frame", { Name = "LobbyLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)

local LIGHT = Color3.fromRGB(246, 243, 252)
local NAVY = Color3.fromRGB(24, 26, 58)
local BAR = Color3.fromRGB(20, 22, 46)
local EDGE = Color3.fromRGB(226, 224, 242)
local GOLD = Color3.fromRGB(255, 196, 46)
local TEAL = Color3.fromRGB(24, 201, 181)
local LIVE = Color3.fromRGB(255, 59, 80)

local function fmt(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- a solid box with its bottom-right corner cut off at 45 degrees (the "chamfer" in the design)
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
local function setChamferColor(box, color)
	for _, p in ipairs(box:GetChildren()) do if p:IsA("Frame") then p.BackgroundColor3 = color end end
end

-- icon: sprite-sheet icon when uploaded, otherwise an emoji glyph in a coloured circle
local GLYPH = { units = "👥", items = "🎒", quests = "📜", summon = "✨", bonds = "🔗", play = "🚀", shop = "🛒", events = "🔥",
	topwaves = "📊", profile = "👤", pass = "🏅", daily = "📅", trophy = "🏆", upd = "📣", gear = "⚙️", gems = "💎" }
local function iconCircle(parent, name, pos, size, color, z)
	local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundColor3 = color, ZIndex = z }, parent)
	corner(c, size) border(c, INK, 2.5)
	if not Icons.New(name, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), ZIndex = z + 1 }, c) then
		new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = GLYPH[name] or "?", TextScaled = true,
			Font = Enum.Font.GothamBold, TextColor3 = WHITE, ZIndex = z + 1 }, c)
		new("UIPadding", { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0), PaddingLeft = UDim.new(0.2, 0), PaddingRight = UDim.new(0.2, 0) }, c)
	end
	return c
end

local function keyBadge(parent, key, z)
	local k = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = WHITE, Rotation = 45, ZIndex = z }, parent)
	corner(k, 4) border(k, INK, 2.5)
	local kl = olabel(parent, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(20, 18), Text = key, ZIndex = z + 1 }, 15, INK)
	kl:FindFirstChildOfClass("UIStroke").Enabled = false
end
local function tagChip(parent, text, color, pos, z)
	local t = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = pos, Size = UDim2.fromOffset(math.max(26, #text * 11 + 14), 24), BackgroundColor3 = color,
		Text = text, Font = Enum.Font.FredokaOne, TextColor3 = WHITE, TextScaled = true, ZIndex = z }, parent)
	corner(t, 12) border(t, INK, 2.5)
	new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, t)
	return t
end
local function hover(b)
	local s = new("UIScale", {}, b)
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1.06 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	b.MouseButton1Down:Connect(function() TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.95 }):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(s, TweenInfo.new(0.1), { Scale = 1.06 }):Play() end)
end

-- the tile: border colour frame + inner fill, both chamfered, dark label bar along the bottom
local TH, CH = 4, 18
local function hudTile(parent, x, y, w, h, opts)
	local b = new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
	chamfer(b, 0, 0, w, h, CH, opts.edge, 1)
	local ci = CH - 0.586 * TH
	local fill = chamfer(b, TH, TH, w - 2 * TH, h - 2 * TH, ci, opts.fill, 2)
	local wide = opts.wide
	local labelH = wide and 0 or 26
	if not wide then
		chamfer(b, TH, h - TH - labelH, w - 2 * TH, labelH, ci, opts.bar or BAR, 3)
		olabel(b, { Position = UDim2.fromOffset(TH + 4, h - TH - labelH + 3), Size = UDim2.fromOffset(w - 2 * TH - 8 - ci * 0.5, labelH - 6), Text = opts.text, ZIndex = 4 }, 17)
		iconCircle(b, opts.icon, UDim2.fromOffset(w / 2, (h - labelH) / 2 + 2), math.floor((h - labelH) * 0.56), opts.edge, 4)
	else
		iconCircle(b, opts.icon, UDim2.fromOffset(TH + 30, h / 2), h - 22, opts.edge, 4)
		olabel(b, { Position = UDim2.fromOffset(TH + 58, 10), Size = UDim2.new(1, -(TH + 70), 1, -20), Text = opts.text, ZIndex = 4 }, 22,
			opts.textColor or INK, Enum.TextXAlignment.Left)
	end
	if opts.key then keyBadge(b, opts.key, 6) end
	hover(b)
	return b, fill
end

-- LEFT: Aegis Shop, 2x3 grid, Events
local left = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, -30), Size = UDim2.fromOffset(234, 508) }, layer)
fitScale(left)
local SQ, GAP = 108, 18
local function lightTile(col, row, text, icon, color, key)
	return hudTile(left, col * (SQ + GAP), 82 + row * (SQ + GAP), SQ, SQ, { text = text, icon = icon, edge = color, fill = LIGHT, key = key })
end
local shopBtn = hudTile(left, 0, 0, 234, 64, { wide = true, text = "Aegis Shop", icon = "shop", edge = Color3.fromRGB(232, 64, 160), fill = LIGHT })
local unitsBtn = lightTile(0, 0, "Units", "units", Color3.fromRGB(255, 138, 31), "H")
local itemsBtn = lightTile(1, 0, "Items", "items", TEAL, "J")
local questsBtn = lightTile(0, 1, "Quests", "quests", Color3.fromRGB(255, 77, 94), "K")
local summonBtn = lightTile(1, 1, "Summon", "summon", Color3.fromRGB(155, 92, 255), "G")
local bondsBtn = lightTile(0, 2, "Bonds", "bonds", Color3.fromRGB(255, 111, 175))
local playBtn, playFill = hudTile(left, SQ + GAP, 82 + 2 * (SQ + GAP), SQ, SQ, { text = "PLAY", icon = "play", edge = TEAL, fill = TEAL, bar = Color3.fromRGB(10, 92, 84) })
local eventsBtn = hudTile(left, 0, 82 + 3 * (SQ + GAP), 234, 64, { wide = true, text = "Events", icon = "events", edge = Color3.fromRGB(255, 138, 31), fill = LIGHT })
tagChip(eventsBtn, "LIVE", LIVE, UDim2.new(1, -8, 0, -10), 7)
local questBadge = tagChip(questsBtn, "3", Color3.fromRGB(255, 63, 170), UDim2.new(1, 6, 0, -8), 7)
questBadge.Visible = false

-- the PLAY tile breathes a little so it reads as the main button
task.spawn(function()
	local glow = new("UIStroke", { Color = TEAL, Thickness = 0, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, playFill:GetChildren()[1])
	TweenService:Create(glow, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 5, Transparency = 0.8 }):Play()
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

-- RIGHT: Aegis Pass card, Top Waves + Profile, Daily
local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, -30), Size = UDim2.fromOffset(234, 508) }, layer)
fitScale(right)
local PASS = Color3.fromRGB(155, 92, 255)
local passBtn = new("TextButton", { Size = UDim2.fromOffset(234, 110), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, right)
chamfer(passBtn, 0, 0, 234, 110, CH, PASS, 1)
chamfer(passBtn, TH, TH, 234 - 2 * TH, 110 - 2 * TH, CH - 0.586 * TH, NAVY, 2)
iconCircle(passBtn, "pass", UDim2.fromOffset(40, 44), 50, PASS, 4)
olabel(passBtn, { Position = UDim2.fromOffset(74, 14), Size = UDim2.fromOffset(150, 26), Text = "Aegis Pass", ZIndex = 4 }, 22, nil, Enum.TextXAlignment.Left)
local passLvl = olabel(passBtn, { Position = UDim2.fromOffset(74, 42), Size = UDim2.fromOffset(150, 18), Text = "LVL 0/50", ZIndex = 4 }, 15, Color3.fromRGB(196, 170, 255), Enum.TextXAlignment.Left)
local passBg = new("Frame", { Position = UDim2.fromOffset(16, 80), Size = UDim2.fromOffset(150, 12), BackgroundColor3 = INK, ZIndex = 4 }, passBtn)
corner(passBg, 6)
new("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(0, 0, 1, -4), BackgroundColor3 = PASS, ZIndex = 5 }, passBg)
olabel(passBtn, { Position = UDim2.fromOffset(150, 76), Size = UDim2.fromOffset(70, 18), Text = "Season 1", ZIndex = 4 }, 13, Color3.fromRGB(170, 179, 255), Enum.TextXAlignment.Right)
hover(passBtn)
passBtn.MouseButton1Click:Connect(function() showToast("The Aegis Pass arrives with Season 1 - coming soon!") end)

local function darkTile(x, y, w, h, text, icon, wide)
	return hudTile(right, x, y, w, h, { text = text, icon = icon, edge = EDGE, fill = NAVY, wide = wide, textColor = WHITE,
		bar = Color3.fromRGB(12, 13, 30) })
end
local topBtn = darkTile(0, 128, SQ, SQ, "Top Waves", "topwaves")
local profileBtn = darkTile(SQ + GAP, 128, SQ, SQ, "Profile", "profile")
local dailyBtn = darkTile(0, 128 + SQ + GAP, 234, 64, "Daily", "daily", true)
topBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
profileBtn.MouseButton1Click:Connect(function() togglePanel("Profile") end)
dailyBtn.MouseButton1Click:Connect(function() showToast("Daily rewards are coming soon!") end)
-- icon circles on dark tiles use a navy ring so the light edge stays the accent
for _, t in ipairs({ topBtn, profileBtn, dailyBtn }) do
	for _, c in ipairs(t:GetChildren()) do
		if c:IsA("Frame") and c.AnchorPoint == Vector2.new(0.5, 0.5) and c:FindFirstChildOfClass("UICorner") then c.BackgroundColor3 = PURPLE end
	end
end

-- TOP RIGHT: trophy | UPD chip
local chip = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 14), Size = UDim2.fromOffset(170, 50), BackgroundColor3 = NAVY }, layer)
corner(chip, 25) border(chip, EDGE, 3)
fitScale(chip)
local trophyBtn = new("TextButton", { Size = UDim2.fromOffset(56, 50), BackgroundTransparency = 1, Text = "" }, chip)
iconCircle(trophyBtn, "trophy", UDim2.fromOffset(30, 25), 36, GOLD, 2)
new("Frame", { Position = UDim2.fromOffset(60, 10), Size = UDim2.fromOffset(2, 30), BackgroundColor3 = EDGE, BorderSizePixel = 0 }, chip)
local updBtn = new("TextButton", { Position = UDim2.fromOffset(64, 0), Size = UDim2.fromOffset(106, 50), BackgroundTransparency = 1, Text = "" }, chip)
iconCircle(updBtn, "upd", UDim2.fromOffset(24, 25), 36, LIVE, 2)
olabel(updBtn, { Position = UDim2.fromOffset(46, 12), Size = UDim2.fromOffset(52, 26), Text = "UPD 1", ZIndex = 3 }, 18, nil, Enum.TextXAlignment.Left)
hover(trophyBtn) hover(updBtn)
trophyBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
updBtn.MouseButton1Click:Connect(function() togglePanel("Updates") end)

-- BOTTOM: gems / coins / settings, team, XP bar
local bottom = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(676, 236) }, layer)
fitScale(bottom)
local pillRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, pillRow)
local function pill(order, iconName, color, w)
	local p = new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(w, 42), BackgroundColor3 = NAVY }, pillRow)
	corner(p, 21) border(p, EDGE, 3)
	iconCircle(p, iconName, UDim2.fromOffset(22, 21), 32, color, 2)
	return olabel(p, { Position = UDim2.fromOffset(44, 8), Size = UDim2.new(1, -56, 1, -16), ZIndex = 3 }, 22, nil, Enum.TextXAlignment.Left)
end
local gemsL = pill(1, "gems", Color3.fromRGB(47, 200, 255), 140)
local coinP = new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(170, 42), BackgroundColor3 = NAVY }, pillRow)
corner(coinP, 21) border(coinP, EDGE, 3)
local coin = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(22, 21), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = GOLD, ZIndex = 2 }, coinP)
corner(coin, 16) border(coin, INK, 2.5)
olabel(coin, { Size = UDim2.fromScale(1, 1), Text = "¥", ZIndex = 3 }, 20)
local coinsL = olabel(coinP, { Position = UDim2.fromOffset(44, 8), Size = UDim2.new(1, -56, 1, -16), ZIndex = 3 }, 22, GOLD, Enum.TextXAlignment.Left)
local gearBtn = new("TextButton", { LayoutOrder = 3, Size = UDim2.fromOffset(42, 42), BackgroundColor3 = NAVY, Text = "" }, pillRow)
corner(gearBtn, 21) border(gearBtn, EDGE, 3)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(26, 26), Text = GLYPH.gear, TextScaled = true, Font = Enum.Font.GothamBold, TextColor3 = WHITE }, gearBtn)
hover(gearBtn)
gearBtn.MouseButton1Click:Connect(function() showToast("Settings are coming soon!") end)

local team = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 0, 132) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, team)
local RARITY_PIPS = { Rare = 1, Epic = 2, Legendary = 3, Mythic = 4, Secret = 5 }
local cards = {}
for i = 1, 6 do
	local c = new("TextButton", { LayoutOrder = i, Size = UDim2.fromOffset(102, 130), BackgroundColor3 = NAVY, Text = "", AutoButtonColor = false }, team)
	corner(c, 10)
	local st = border(c, EDGE, 3)
	local art = new("CanvasGroup", { Position = UDim2.fromOffset(5, 26), Size = UDim2.fromOffset(92, 64), BackgroundColor3 = Color3.fromRGB(60, 60, 90), BorderSizePixel = 0 }, c)
	corner(art, 6)
	local stripes = {}
	for k = -3, 6 do
		table.insert(stripes, new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(k * 18, 32), Size = UDim2.fromOffset(7, 150),
			BackgroundColor3 = WHITE, BackgroundTransparency = 0.82, BorderSizePixel = 0, Rotation = 35 }, art))
	end
	local artL = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "unit art", Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = WHITE, TextTransparency = 0.35 }, art)
	local icon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 1, Visible = false }, art)
	local lvl = new("Frame", { Position = UDim2.fromOffset(5, 4), Size = UDim2.fromOffset(52, 18), BackgroundColor3 = INK }, c)
	corner(lvl, 6)
	local lvlL = olabel(lvl, { Position = UDim2.fromOffset(3, 2), Size = UDim2.new(1, -6, 1, -4) }, 12)
	olabel(c, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(22, 18), Text = tostring(i) }, 14, Color3.fromRGB(170, 179, 255), Enum.TextXAlignment.Right)
	local pips = new("Frame", { Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1 }, c)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, pips)
	local pipList = {}
	for k = 1, 5 do
		local holder = new("Frame", { LayoutOrder = k, Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1 }, pips)
		local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8), Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0 }, holder)
		border(d, INK, 1.5)
		pipList[k] = holder
	end
	local bar = new("Frame", { Position = UDim2.new(0, 3, 1, -25), Size = UDim2.new(1, -6, 0, 22), BackgroundColor3 = BAR, BorderSizePixel = 0 }, c)
	corner(bar, 6)
	local cost = olabel(bar, { Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 1, -6) }, 15, GOLD)
	local plus = olabel(c, { Size = UDim2.fromScale(1, 1), Text = "+" }, 40, Color3.fromRGB(110, 116, 170))
	hover(c)
	c.MouseButton1Click:Connect(function() togglePanel("Units") end)
	cards[i] = { Card = c, Stroke = st, Art = art, Stripes = stripes, ArtL = artL, Icon = icon, Lvl = lvl, LvlL = lvlL, Pips = pips, PipList = pipList, Bar = bar, Cost = cost, Plus = plus }
end

-- segmented XP bar
local SEGS = 24
local xpBg = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 194), Size = UDim2.fromOffset(560, 18), BackgroundColor3 = INK }, bottom)
corner(xpBg, 5) border(xpBg, EDGE, 2)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, xpBg)
new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, xpBg)
local segW = (560 - 8 - 3 * (SEGS - 1)) / SEGS
local segs = {}
for k = 1, SEGS do
	segs[k] = new("Frame", { LayoutOrder = k, Size = UDim2.fromOffset(segW, 10), BackgroundColor3 = TEAL, BorderSizePixel = 0 }, xpBg)
	corner(segs[k], 2)
end
local xpText = olabel(bottom, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 214), Size = UDim2.fromOffset(360, 18) }, 15)

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
		for _, o in ipairs({ c.Lvl, c.Art, c.Pips, c.Bar }) do o.Visible = filled end
		c.Plus.Visible = not filled
		if filled then
			local r = Config.Rarities[def.Rarity]
			local rc = (r and r.Color) or def.Color or PURPLE
			c.Card.BackgroundColor3 = NAVY
			c.Card.BackgroundTransparency = 0
			c.Stroke.Color = rc:Lerp(WHITE, 0.35)
			c.Art.BackgroundColor3 = rc:Lerp(INK, 0.25)
			c.LvlL.Text = "Lvl " .. (u.Level or 1)
			local hasIcon = Icons.Apply(c.Icon, Icons.Unit[u.Id])
			c.Icon.Visible = hasIcon
			c.ArtL.Text = hasIcon and "" or (def.DisplayName or u.Id)
			c.ArtL.TextSize = hasIcon and 12 or 14
			c.ArtL.Font = Enum.Font.FredokaOne
			c.ArtL.TextTransparency = 0
			c.ArtL.TextWrapped = true
			c.Cost.Text = "¥ " .. fmt(def.Cost or 0)
			local n = RARITY_PIPS[def.Rarity] or 1
			if u.Evolved then n += 1 end
			for k = 1, 5 do c.PipList[k].Visible = k <= math.min(n, 5) end
			local t = u.Trait and Config.GetTrait(u.Trait)
			if t then c.PipList[1]:FindFirstChildOfClass("Frame").BackgroundColor3 = t.Color end
		else
			c.Card.BackgroundColor3 = NAVY
			c.Card.BackgroundTransparency = 0.35
			c.Stroke.Color = Color3.fromRGB(90, 96, 150)
		end
	end
	local level = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local need = level * 100
	local frac = math.clamp(xp / need, 0, 1)
	local lit = math.floor(frac * SEGS + 0.5)
	for k = 1, SEGS do
		TweenService:Create(segs[k], TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, (k - 1) * 0.01),
			{ BackgroundTransparency = k <= lit and 0 or 0.85 }):Play()
	end
	xpText.Text = ("Lvl %d  ·  %s / %s XP"):format(level, fmt(xp), fmt(need))
end
for _, a in ipairs({ "Gems", "EquippedUids", "Inventory", "Level", "XP", "AegisShards" }) do
	player:GetAttributeChangedSignal(a):Connect(updateBottom)
end
updateBottom()
