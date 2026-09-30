-- HudIcons (ModuleScript): the Lobby HUD icons (Material Symbols Rounded, filled) as one white sprite sheet, 4 x 4 cells of 128px.
-- Upload icons/hud/HudIcons.png into the child ImageLabel "Sheet" (select it > Properties > Image > Add Image).
-- Until then the HUD shows emoji stand-ins; it switches to the real icons as soon as Sheet.Image is set.
local HudIcons = {}
local COLS, CELL = 4, 128
local NAMES = { "storefront", "star", "backpack", "receipt_long", "auto_awesome", "link", "rocket_launch", "local_fire_department",
	"military_tech", "leaderboard", "badge", "calendar_month", "settings", "emoji_events", "campaign" }
local EMOJI = { storefront = "🏪", star = "👥", backpack = "🎒", receipt_long = "🧾", auto_awesome = "✨", link = "🔗", rocket_launch = "🚀",
	local_fire_department = "🔥", military_tech = "🎖️", leaderboard = "📊", badge = "👤", calendar_month = "📅", settings = "⚙️",
	emoji_events = "🏆", campaign = "📣" }
local index = {}
for i, n in ipairs(NAMES) do index[n] = i - 1 end

local sheet = script:WaitForChild("Sheet", 5)
HudIcons.Changed = sheet and sheet:GetPropertyChangedSignal("Image")
function HudIcons.SheetId() return sheet and sheet.Image or "" end

-- returns a Frame holding the icon (tinted ImageLabel) and an emoji fallback; it swaps itself when the sheet arrives
function HudIcons.New(name, props, parent, tint)
	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. name
	holder.BackgroundTransparency = 1
	for k, v in pairs(props or {}) do holder[k] = v end
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.ImageColor3 = tint or Color3.new(1, 1, 1)
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = holder.ZIndex
	img.Parent = holder
	local emo = Instance.new("TextLabel")
	emo.BackgroundTransparency = 1
	emo.Size = UDim2.fromScale(0.8, 0.8)
	emo.Position = UDim2.fromScale(0.1, 0.1)
	emo.TextScaled = true
	emo.Text = EMOJI[name] or "?"
	emo.ZIndex = holder.ZIndex
	emo.Parent = holder
	local function sync()
		local i = index[name]
		local id = HudIcons.SheetId()
		local has = i ~= nil and id ~= ""
		img.Visible, emo.Visible = has, not has
		if has then
			img.Image = id
			-- 8px padding inside each 128px cell
			img.ImageRectOffset = Vector2.new((i % COLS) * CELL + 8, math.floor(i / COLS) * CELL + 8)
			img.ImageRectSize = Vector2.new(CELL - 16, CELL - 16)
		end
	end
	sync()
	if HudIcons.Changed then HudIcons.Changed:Connect(sync) end
	holder.Parent = parent
	return holder
end

return HudIcons
