-- SummonHallFX (LocalScript) -> StarterPlayerScripts
-- Client-only motion for the Summon Hall so the server doesn't stream CFrames every frame:
-- spins the "Spin_*" rings above the summon platform and bobs the hologram placeholders.
local RunService = game:GetService("RunService")

local spinners = {} -- part -> { base = CFrame, speed = rad/s }
local holos = {}    -- model -> base pivot

local function add(inst)
	if inst:IsA("BasePart") and inst.Name:match("^Spin_") then
		local speed = inst.Name:match("RingB") and -0.9 or 0.45
		spinners[inst] = { base = inst.CFrame, speed = speed }
	elseif inst:IsA("Model") and inst.Name:match("^Placeholder_") then
		task.defer(function() holos[inst] = inst:GetPivot() end)
	end
end
for _, d in ipairs(workspace:GetDescendants()) do add(d) end
workspace.DescendantAdded:Connect(add)
workspace.DescendantRemoving:Connect(function(d) spinners[d] = nil holos[d] = nil end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for p, s in pairs(spinners) do
		-- spin around world-up through the ring's centre, keeping its tilt
		p.CFrame = CFrame.new(s.base.Position) * CFrame.Angles(0, t * s.speed, 0) * s.base.Rotation
	end
	for m, base in pairs(holos) do
		m:PivotTo(base * CFrame.new(0, math.sin(t * 2) * 0.15, 0))
	end
end)
