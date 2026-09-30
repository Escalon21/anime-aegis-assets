-- UnitPreview (ModuleScript, client): a live, animated 3D unit inside a ViewportFrame (team cards, unit screens).
-- Uses the real model from ReplicatedStorage.UnitModels when there is one, otherwise VisualService's R6 stand-in.
-- Plays Visual.Animations.Idle when the unit has one; otherwise a procedural idle (breathing, head sway, arm swing, weight shift).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local VS = require(ReplicatedStorage:WaitForChild("VisualService"))

local UnitPreview = {}
local live = {} -- mounted previews that need the procedural idle

local function joints(model)
	local j = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then j[d.Name] = d end
	end
	return j
end

-- opts: { framing = "bust" | "full", yaw = degrees, popOut = bool }
function UnitPreview.Mount(parent, unitId, opts)
	opts = opts or {}
	local def = Config.Units[unitId]
	if not def then return nil end
	local visual = def.Visual or {}

	local vp = Instance.new("ViewportFrame")
	vp.Name = "UnitPreview"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(150, 150, 170)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.6, -1, 0.8)
	if parent then vp.ZIndex = parent.ZIndex end
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam

	local model = VS.CreateModel("UnitModels", visual.Model or unitId, visual, def.Color)
	model.Parent = world
	VS.Place(model, Vector3.zero, math.rad(180 + (opts.yaw or 18)))
	local cf, size = model:GetBoundingBox()
	local top = cf.Position.Y + size.Y / 2
	local h = size.Y
	-- bust: head + chest fill the card (like the reference shot); full: whole body
	local target, dist
	if opts.framing == "full" then
		target, dist = Vector3.new(0, h * 0.5, 0), h * 2.1
	else
		target, dist = Vector3.new(0, top - h * 0.36, 0), h * 1.2
	end
	cam.CFrame = CFrame.lookAt(target + Vector3.new(0, h * 0.06, dist), target)

	local entry = { Model = model, Joints = joints(model), Phase = math.random() * 10, Viewport = vp }
	-- real idle animation if the unit has one
	local idle = visual.Animations and visual.Animations.Idle
	entry.Track = idle and VS.Play(model, idle, true)
	if not entry.Track then live[vp] = entry end
	vp.Parent = parent
	vp.Destroying:Connect(function() live[vp] = nil end)
	return vp
end

-- cached previews (inventory cards are rebuilt on every refresh): same key + unit = same viewport, just re-parented
local pool = {}
function UnitPreview.Pooled(key, unitId, opts)
	local e = pool[key]
	if e and e.UnitId == unitId and not e.Dead then return e.Vp end
	if e and not e.Dead then e.Vp:Destroy() end
	local vp = UnitPreview.Mount(nil, unitId, opts)
	if not vp then return nil end
	local entry = { UnitId = unitId, Vp = vp }
	pool[key] = entry
	vp.Destroying:Connect(function() entry.Dead = true end)
	return vp
end

function UnitPreview.Unmount(vp)
	if vp then
		live[vp] = nil
		vp:Destroy()
	end
end

-- only animate previews that are actually showing
local function onScreen(vp)
	local p, sz = vp.AbsolutePosition, vp.AbsoluteSize
	local view = workspace.CurrentCamera.ViewportSize
	if sz.X < 2 or p.X > view.X or p.Y > view.Y or p.X + sz.X < 0 or p.Y + sz.Y < 0 then return false end
	local a = vp.Parent
	while a and not a:IsA("LayerCollector") do
		if a:IsA("GuiObject") and not a.Visible then return false end
		a = a.Parent
	end
	return a ~= nil and a.Enabled
end

-- procedural idle for every mounted preview without an animation asset
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for vp, e in pairs(live) do
		if vp.Parent and vp.Visible and onScreen(vp) then
			local p = t + e.Phase
			local j = e.Joints
			local breathe = math.sin(p * 2.1)
			local sway = math.sin(p * 0.9)
			-- RootJoint/Neck frames: Z = up, X = sideways (Roblox R6 C0 layout)
			if j.RootJoint then j.RootJoint.Transform = CFrame.new(0, 0, breathe * 0.045) * CFrame.Angles(0, sway * 0.035, sway * 0.06) end
			if j.Neck then j.Neck.Transform = CFrame.Angles(breathe * 0.04 - 0.03, 0, -sway * 0.12) end
			-- shoulders: Z = forward/back swing
			if j["Right Shoulder"] then j["Right Shoulder"].Transform = CFrame.Angles(math.sin(p * 1.3) * 0.05, 0, 0.1 + breathe * 0.06) end
			if j["Left Shoulder"] then j["Left Shoulder"].Transform = CFrame.Angles(-math.sin(p * 1.3) * 0.05, 0, -0.1 - breathe * 0.06) end
			if j["Right Hip"] then j["Right Hip"].Transform = CFrame.Angles(0, 0, -sway * 0.04) end
			if j["Left Hip"] then j["Left Hip"].Transform = CFrame.Angles(0, 0, -sway * 0.04) end
		end
	end
end)

return UnitPreview
