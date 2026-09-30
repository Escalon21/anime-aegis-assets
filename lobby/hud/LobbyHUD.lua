----------------------------------------------------------------- lobby layer (hidden during battles)  -- HUD v5 (built from Omar's "Lobby HUD.dc.html", sizes in design px @1080p)
local layer = new("Frame", { Name = "LobbyLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local HudIcons = require(ReplicatedStorage:WaitForChild("HudIcons"))
local TextService = game:GetService("TextService")

local C = {
	ink = Color3.fromHex("16181F"), panel = Color3.fromHex("262A35"), light = Color3.fromHex("E4E7EF"), edge = Color3.fromHex("3a3f52"),
	pink = Color3.fromHex("FF3FA4"), amber = Color3.fromHex("FFB23F"), teal = Color3.fromHex("38F2C0"), red = Color3.fromHex("E8413A"),
	lav = Color3.fromHex("8E86C9"), lavText = Color3.fromHex("b9b3ec"), white = Color3.new(1, 1, 1),
}
-- the design uses Chakra Petch; Sarpanch is the closest Roblox font (same squared, cut-corner letters)
local FONT = Font.fromName("Sarpanch", Enum.FontWeight.Heavy)
local FONT_SEMI = Font.fromName("Sarpanch", Enum.FontWeight.Bold)

-- the whole HUD scales like the design: 1 design px = 1 px on a 1080p screen
local function hudFit(o)
	local s = new("UIScale", {}, o)
	local function f()
		local vp = workspace.CurrentCamera.ViewportSize
		s.Scale = math.clamp(math.min(vp.Y / 1080, vp.X / 1250), 0.42, 1.4)
	end
	f()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(f)
end

local function fmt(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
local function txt(parent, props, size, color, font)
	local l = new("TextLabel", { BackgroundTransparency = 1, FontFace = font or FONT, TextColor3 = color or C.white, TextSize = size, Text = "" }, parent)
	for k, v in pairs(props) do l[k] = v end
	return l
end
local function measure(text, size, font)
	local p = Instance.new("GetTextBoundsParams")
	p.Text, p.Font, p.Size, p.Width = text, font or FONT, size, 2000
	local ok, v = pcall(TextService.GetTextBoundsAsync, TextService, p)
	return ok and v.X or #text * size * 0.55
end

-- clip-path polygon(tl 0, 100% 0, 100% calc(100%-br), calc(100%-br) 100%, 0 100%, 0 tl): corners cut at 45 degrees.
-- Built from rectangles + two triangle squares (hard UIGradient cut); sizes are relative so the box can be resized later.
local function tri(parent, pos, c, color, keepBottomRight)
	local t = new("Frame", { Position = pos, Size = UDim2.fromOffset(c, c), BackgroundColor3 = color, BorderSizePixel = 0 }, parent)
	local a, b = keepBottomRight and 1 or 0, keepBottomRight and 0 or 1
	new("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.48, a),
		NumberSequenceKeypoint.new(0.52, b), NumberSequenceKeypoint.new(1, b) }) }, t)
end
local function cut(parent, x, y, w, h, tl, br, color)
	local box = new("Frame", { Name = "Cut", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1 }, parent)
	local function rect(pos, size) new("Frame", { Position = pos, Size = size, BackgroundColor3 = color, BorderSizePixel = 0 }, box) end
	rect(UDim2.fromOffset(0, tl), UDim2.new(1, 0, 1, -tl - br))
	if tl > 0 then
		rect(UDim2.fromOffset(tl, 0), UDim2.new(1, -tl, 0, tl))
		tri(box, UDim2.fromOffset(0, 0), tl, color, true)
	end
	if br > 0 then
		rect(UDim2.new(0, 0, 1, -br), UDim2.new(1, -br, 0, br))
		tri(box, UDim2.new(1, -br, 1, -br), br, color, false)
	end
	return box
end
local function recolor(box, color)
	for _, p in ipairs(box:GetChildren()) do if p:IsA("Frame") then p.BackgroundColor3 = color end end
end
local function icon(parent, name, cx, cy, size, tint)
	return HudIcons.New(name, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(size, size) }, parent, tint)
end
local function dot(parent, text, color, w)
	local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(w - 7, 7), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = color }, parent)
	corner(d, 12)
	new("UIStroke", { Color = C.ink, Thickness = 2 }, d)
	txt(d, { Size = UDim2.fromScale(1, 1), Text = text }, 14)
	return d
end
local function hover(b, amount)
	local s = new("UIScale", {}, b)
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = amount or 1.05 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	b.MouseButton1Down:Connect(function() TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.96 }):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(s, TweenInfo.new(0.1), { Scale = amount or 1.05 }):Play() end)
	return s
end
local function button(parent, x, y, w, h)
	return new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
end

-- toast (design: top 96, #16181F, lavender border, title + teal subtitle)
local toastBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(360, 80), BackgroundTransparency = 1, Visible = false }, layer)
hudFit(toastBox)
local toastEdge = cut(toastBox, 0, 0, 360, 80, 12, 12, C.lav)
local toastFill = cut(toastBox, 2, 2, 356, 76, 11, 11, C.ink)
local toastTitle = txt(toastBox, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 30) }, 24)
local toastSub = txt(toastBox, { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 20) }, 16, C.teal, FONT_SEMI)
local toastToken = 0
local function hudToast(title, sub)
	toastToken += 1
	local my = toastToken
	toastTitle.Text, toastSub.Text = title, sub or ""
	local w = math.max(360, 52 + math.max(measure(title, 24), measure(sub or "", 16, FONT_SEMI)))
	toastBox.Size = UDim2.fromOffset(w, 80)
	toastEdge.Size = UDim2.fromOffset(w, 80)
	toastFill.Size = UDim2.fromOffset(w - 4, 76)
	toastBox.Visible = true
	task.delay(1.8, function() if toastToken == my then toastBox.Visible = false end end)
end

-- a menu tile: coloured frame, dark body, light top with an icon circle, divider, label
local function tile(parent, x, y, w, h, o)
	local b = button(parent, x, y, w, h)
	cut(b, 0, 0, w, h, 14, 14, o.color)
	cut(b, 4, 4, w - 8, h - 8, 11, 11, o.body or C.panel)
	cut(b, 4, 4, w - 8, 64, 11, 0, o.top or C.light)
	if o.circle ~= false then
		local circ = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(w / 2, 36), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = o.color }, b)
		corner(circ, 25)
		icon(circ, o.icon, 25, 25, o.iconSize or 34, o.iconTint or C.panel)
		new("Frame", { Position = UDim2.fromOffset(4, 68), Size = UDim2.fromOffset(w - 8, 3), BackgroundColor3 = o.color, BorderSizePixel = 0 }, b)
	else
		icon(b, o.icon, w / 2, 36, o.iconSize or 46, o.iconTint)
	end
	local lh = o.labelH or 33
	txt(b, { Position = UDim2.fromOffset(4, h - 4 - lh), Size = UDim2.fromOffset(w - 8, lh), Text = o.text }, o.labelSize or 20, o.labelColor)
	if o.key then
		local k = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(28, 28), Rotation = 45, BackgroundColor3 = C.ink, BorderSizePixel = 0 }, b)
		new("UIStroke", { Color = o.color, Thickness = 2 }, k)
		txt(b, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(20, 20), Text = o.key }, 15)
	end
	hover(b, o.hover)
	return b
end

-- LEFT MENU (grid 108 + 108, gap 12)
local left = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Size = UDim2.fromOffset(228, 552) }, layer)
hudFit(left)
-- Aegis Shop: light icon square + pink divider + label
local shopBtn = button(left, 0, 0, 228, 72)
cut(shopBtn, 0, 0, 228, 72, 14, 14, C.pink)
cut(shopBtn, 4, 4, 220, 64, 11, 11, C.panel)
cut(shopBtn, 4, 4, 64, 64, 11, 0, C.light)
icon(shopBtn, "storefront", 36, 36, 40, C.panel)
new("Frame", { Position = UDim2.fromOffset(68, 4), Size = UDim2.fromOffset(3, 64), BackgroundColor3 = C.pink, BorderSizePixel = 0 }, shopBtn)
txt(shopBtn, { Position = UDim2.fromOffset(71, 4), Size = UDim2.fromOffset(153, 64), Text = "Aegis Shop" }, 26)
hover(shopBtn, 1.04)

local unitsBtn = tile(left, 0, 84, 108, 108, { color = C.amber, icon = "star", text = "Units", key = "H" })
local itemsBtn = tile(left, 120, 84, 108, 108, { color = C.teal, icon = "backpack", text = "Items", key = "J" })
local questsBtn = tile(left, 0, 204, 108, 108, { color = C.red, icon = "receipt_long", iconSize = 32, iconTint = C.white, text = "Quests", key = "K" })
local summonBtn = tile(left, 120, 204, 108, 108, { color = C.lav, icon = "auto_awesome", iconTint = C.white, text = "Summon", key = "G" })
local bondsBtn = tile(left, 0, 324, 108, 108, { color = C.pink, icon = "link", iconTint = C.white, text = "Bonds" })
local playBtn = tile(left, 120, 324, 108, 108, { color = C.teal, body = C.teal, top = C.panel, circle = false, icon = "rocket_launch", iconSize = 46,
	iconTint = C.teal, text = "PLAY", labelSize = 22, labelH = 36, labelColor = C.ink })
local eventsBtn = tile(left, 0, 444, 228, 108, { color = C.amber, icon = "local_fire_department", text = "Events" })
local live = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 10, 0, -8), Size = UDim2.fromOffset(46, 21), BackgroundColor3 = C.red, BorderSizePixel = 0 }, eventsBtn)
new("UIStroke", { Color = C.ink, Thickness = 2 }, live)
txt(live, { Size = UDim2.fromScale(1, 1), Text = "LIVE" }, 12)
local questBadge = dot(questsBtn, "3", C.pink, 108)
questBadge.Visible = false

-- PLAY breathes a little so it reads as the main button
task.spawn(function()
	local s = playBtn:FindFirstChildOfClass("UIScale")
	while playBtn.Parent do
		if s.Scale == 1 then
			local up = TweenService:Create(s, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Scale = 1.03 })
			up:Play() up.Completed:Wait()
			if math.abs(s.Scale - 1.03) < 0.001 then TweenService:Create(s, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Scale = 1 }):Play() end
			task.wait(1.4)
		else
			task.wait(0.4)
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
	local label = questBadge:FindFirstChildOfClass("TextLabel")
	local function sync()
		local n = qg:GetAttribute("ClaimableCount")
		label.Text = n and tostring(n) or "!"
		questBadge.Visible = qg:GetAttribute("Claimable") == true
	end
	qg:GetAttributeChangedSignal("Claimable"):Connect(sync)
	qg:GetAttributeChangedSignal("ClaimableCount"):Connect(sync)
	sync()
end)

-- RIGHT COLUMN (112 wide, gap 12)
local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -22, 0.5, 0), Size = UDim2.fromOffset(112, 480) }, layer)
hudFit(right)
local passBtn = button(right, 0, 0, 112, 132)
cut(passBtn, 0, 0, 112, 132, 14, 14, C.lav)
cut(passBtn, 4, 4, 104, 124, 11, 11, C.ink)
txt(passBtn, { Position = UDim2.fromOffset(4, 12), Size = UDim2.fromOffset(104, 18), Text = "LVL 0/50" }, 14, C.light, FONT_SEMI)
icon(passBtn, "military_tech", 56, 56, 48, C.lav)
txt(passBtn, { Position = UDim2.fromOffset(4, 82), Size = UDim2.fromOffset(104, 18), Text = "Aegis Pass" }, 18)
txt(passBtn, { Position = UDim2.fromOffset(4, 101), Size = UDim2.fromOffset(104, 17), Text = "Season 1" }, 13, C.lavText, FONT_SEMI)
hover(passBtn)
passBtn.MouseButton1Click:Connect(function() hudToast("Aegis Pass", "Season 1 · coming soon") end)

local function darkTile(y, text, iconName, tint)
	local b = button(right, 0, y, 112, 104)
	cut(b, 0, 0, 112, 104, 14, 14, C.light)
	cut(b, 4, 4, 104, 96, 11, 11, C.panel)
	icon(b, iconName, 56, 39, 46, tint)
	txt(b, { Position = UDim2.fromOffset(4, 65), Size = UDim2.fromOffset(104, 23), Text = text }, 18)
	hover(b)
	return b
end
local topBtn = darkTile(144, "Top Waves", "leaderboard", C.teal)
local profileBtn = darkTile(260, "Profile", "badge", C.light)
local dailyBtn = darkTile(376, "Daily", "calendar_month", C.amber)
dot(dailyBtn, "!", C.red, 112)
topBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
profileBtn.MouseButton1Click:Connect(function() togglePanel("Profile") end)
dailyBtn.MouseButton1Click:Connect(function() hudToast("Daily Rewards", "Coming soon") end)

-- TOP RIGHT: trophy | campaign "UPD 1"
local chipW = 16 + 26 + 12 + 2 + 12 + 26 + 12 + math.ceil(measure("UPD 1", 19)) + 16
local chip = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 18), Size = UDim2.fromOffset(chipW, 50), BackgroundTransparency = 1 }, layer)
hudFit(chip)
cut(chip, 0, 0, chipW, 50, 10, 10, C.edge)
cut(chip, 2, 2, chipW - 4, 46, 9, 9, C.ink)
local trophyBtn = button(chip, 0, 0, 16 + 26 + 6, 50)
icon(trophyBtn, "emoji_events", 16 + 13, 25, 26, C.amber)
new("Frame", { Position = UDim2.fromOffset(16 + 26 + 12, 14), Size = UDim2.fromOffset(2, 22), BackgroundColor3 = C.edge, BorderSizePixel = 0 }, chip)
local updX = 16 + 26 + 12 + 2 + 6
local updBtn = button(chip, updX, 0, chipW - updX, 50)
icon(updBtn, "campaign", 6 + 13, 25, 26, C.teal)
txt(updBtn, { Position = UDim2.fromOffset(6 + 26 + 12, 0), Size = UDim2.new(1, -(6 + 26 + 12), 1, 0), Text = "UPD 1", TextXAlignment = Enum.TextXAlignment.Left }, 19, C.light)
hover(trophyBtn, 1.08) hover(updBtn, 1.05)
trophyBtn.MouseButton1Click:Connect(function() togglePanel("TopWaves") end)
updBtn.MouseButton1Click:Connect(function() togglePanel("Updates") end)

-- BOTTOM CENTRE: currency chips, team, XP bar
local bottom = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.fromOffset(784, 230) }, layer)
hudFit(bottom)
local chipRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, chipRow)
local function currency(order, textStart, color)
	local f = new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(150, 52), BackgroundTransparency = 1 }, chipRow)
	cut(f, 0, 0, 1, 1, 10, 10, C.edge).Size = UDim2.fromScale(1, 1)
	cut(f, 2, 2, 1, 1, 9, 9, C.ink).Size = UDim2.new(1, -4, 1, -4)
	local l = txt(f, { Position = UDim2.fromOffset(textStart, 0), Size = UDim2.new(1, -textStart, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }, 26, color)
	return f, l, textStart
end
local gemChip, gemsL, gemStart = currency(1, 2 + 12 + 28 + 12, C.white)
local gem = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(2 + 12 + 14, 26), Size = UDim2.fromOffset(22, 22), Rotation = 45, BackgroundColor3 = C.lav, BorderSizePixel = 0 }, gemChip)
new("UIStroke", { Color = C.teal, Thickness = 3 }, gem)
local yenChip, coinsL, yenStart = currency(2, 2 + 12 + 34 + 12, C.amber)
local coin = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(2 + 12 + 17, 26), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.amber }, yenChip)
corner(coin, 14)
new("UIStroke", { Color = Color3.fromHex("ffd79a"), Thickness = 3 }, coin)
txt(coin, { Size = UDim2.fromScale(1, 1), Text = "¥" }, 15, Color3.fromHex("6b4200"))
local gearBtn = new("TextButton", { LayoutOrder = 3, Size = UDim2.fromOffset(48, 48), BackgroundColor3 = C.panel, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, chipRow)
new("UIStroke", { Color = C.edge, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gearBtn)
icon(gearBtn, "settings", 24, 24, 28, C.light)
gearBtn.MouseEnter:Connect(function() gearBtn.BackgroundColor3 = C.edge end)
gearBtn.MouseLeave:Connect(function() gearBtn.BackgroundColor3 = C.panel end)
gearBtn.MouseButton1Click:Connect(function() hudToast("Settings", "Audio · graphics · controls - coming soon") end)
local function fitChip(f, start, text) f.Size = UDim2.fromOffset(math.ceil(start + measure(text, 26) + 20 + 2), 52) end

-- team cards 116 x 128
local team = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 128) }, bottom)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, team)
local RARITY_PIPS = { Rare = 1, Epic = 2, Legendary = 3, Mythic = 4, Secret = 5 }
local cards = {}
for i = 1, 6 do
	local c = new("TextButton", { LayoutOrder = i, Size = UDim2.fromOffset(116, 128), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, team)
	local card = new("Frame", { Size = UDim2.fromOffset(116, 128), BackgroundTransparency = 1 }, c)
	local frame = cut(card, 0, 0, 116, 128, 12, 12, C.ink)
	local fill = cut(card, 4, 4, 108, 120, 9, 9, C.panel)
	local art = new("CanvasGroup", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(96, 84), BackgroundColor3 = C.ink, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, card)
	for k = -3, 8 do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(k * 17, 42), Size = UDim2.fromOffset(6, 200), Rotation = 45,
			BackgroundColor3 = C.ink, BackgroundTransparency = 0.818, BorderSizePixel = 0 }, art)
	end
	local artL = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "unit art", Font = Enum.Font.RobotoMono, TextSize = 11, TextColor3 = C.ink }, art)
	local unitIcon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(66, 66), BackgroundTransparency = 1, Visible = false }, art)
	local bar = cut(card, 4, 94, 108, 30, 0, 9, C.ink)
	local cost = txt(card, { Position = UDim2.fromOffset(4, 94), Size = UDim2.fromOffset(108, 30) }, 19, C.amber)
	local pips = new("Frame", { Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1 }, card)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, pips)
	local pipList = {}
	for k = 1, 5 do
		local holder = new("Frame", { LayoutOrder = k, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, pips)
		local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Rotation = 45, BackgroundColor3 = C.white, BorderSizePixel = 0 }, holder)
		new("UIStroke", { Color = C.ink, Thickness = 2 }, d)
		pipList[k] = holder
	end
	local plus = txt(card, { Size = UDim2.fromScale(1, 1), Text = "+" }, 40, Color3.fromHex("6b7089"))
	local lvl = txt(card, { Position = UDim2.fromOffset(8, -8), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = C.ink,
		BorderSizePixel = 0 }, 14)
	new("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, lvl)
	local slot = new("Frame", { Position = UDim2.new(1, -28, 0, -8), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.light, BorderSizePixel = 0 }, card)
	txt(slot, { Size = UDim2.fromScale(1, 1), Text = tostring(i) }, 13, C.ink)
	-- hover = the design's "selected" look: lift 8px + white frame
	c.MouseEnter:Connect(function() TweenService:Create(card, TweenInfo.new(0.12), { Position = UDim2.fromOffset(0, -8) }):Play() recolor(frame, C.white) end)
	c.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(0.12), { Position = UDim2.fromOffset(0, 0) }):Play() recolor(frame, C.ink) end)
	c.MouseButton1Click:Connect(function() togglePanel("Units") end)
	cards[i] = { Fill = fill, Art = art, ArtL = artL, Icon = unitIcon, Bar = bar, Cost = cost, Pips = pips, PipList = pipList, Plus = plus, Lvl = lvl }
end

-- XP bar 780 x 22, border 2, teal fill, 10 ticks, outlined text
local xpBg = new("Frame", { Position = UDim2.fromOffset(2, 206), Size = UDim2.fromOffset(780, 22), BackgroundColor3 = C.ink, BorderSizePixel = 0, ClipsDescendants = true }, bottom)
new("UIStroke", { Color = C.edge, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, xpBg)
local xpBar = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.teal, BorderSizePixel = 0 }, xpBg)
for k = 1, 9 do
	new("Frame", { Position = UDim2.new(k / 10, -2, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = C.ink, BackgroundTransparency = 0.45, BorderSizePixel = 0 }, xpBg)
end
local xpText = txt(xpBg, { Size = UDim2.fromScale(1, 1) }, 15)
new("UIStroke", { Color = C.ink, Thickness = 1 }, xpText)

local function decodeAttr(a, fallback)
	local ok, v = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute(a) or "")
	return (ok and type(v) == "table") and v or fallback
end
local function updateBottom()
	gemsL.Text = fmt(player:GetAttribute("Gems") or 0)
	coinsL.Text = fmt(player:GetAttribute("AegisShards") or 0)
	task.spawn(fitChip, gemChip, gemStart, gemsL.Text)
	task.spawn(fitChip, yenChip, yenStart, coinsL.Text)
	local inv = decodeAttr("Inventory", {})
	local eqU = decodeAttr("EquippedUids", {})
	local byUid = {}
	for _, u in ipairs(inv) do if type(u) == "table" then byUid[u.Uid] = u end end
	for i = 1, 6 do
		local c = cards[i]
		local u = eqU[i] and byUid[eqU[i]]
		local def = u and Config.Units[u.Id]
		local filled = def ~= nil
		for _, o in ipairs({ c.Art, c.Bar, c.Cost, c.Pips, c.Lvl }) do o.Visible = filled end
		c.Plus.Visible = not filled
		if filled then
			local r = Config.Rarities[def.Rarity]
			recolor(c.Fill, (r and r.Color) or def.Color or C.lav)
			c.Lvl.Text = "Lvl " .. (u.Level or 1)
			local hasIcon = Icons.Apply(c.Icon, Icons.Unit[u.Id])
			c.Icon.Visible = hasIcon
			c.ArtL.Visible = not hasIcon
			c.Cost.Text = "¥" .. fmt(def.Cost or 0)
			local n = RARITY_PIPS[def.Rarity] or 1
			if u.Evolved then n += 1 end
			for k = 1, 5 do c.PipList[k].Visible = k <= math.min(n, 5) end
			local t = u.Trait and Config.GetTrait(u.Trait)
			c.PipList[1]:FindFirstChildOfClass("Frame").BackgroundColor3 = t and t.Color or C.white
		else
			recolor(c.Fill, C.panel)
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
