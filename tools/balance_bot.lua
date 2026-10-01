-- balance_bot.lua: Studio playtest bot (run on the CLIENT with execute_luau). Defines _G.RunBot(mode, actId) and _G.BotLog.
-- Places the equipped team on the best-scoring spots near the path (cycling the team), turns on auto-upgrade, votes 3x.
-- Lives in the place as ServerStorage.DevTools.BalanceBot (copied to ReplicatedStorage in Studio). Client: require(RS.DevTools.BalanceBot).
-- Server first: DebugData:Invoke(player, "snapshot") + ("keeplevel", 15) for 3x; afterwards ("keeplevel", nil) + "restore".
local RS = game.ReplicatedStorage
local R = RS.Remotes
local Config = require(RS.GameConfig)
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

_G.BotLog = _G.BotLog or {}
_G.RunBot = function(mode, actId, opts)
	opts = opts or {}
	local log = { Mode = mode, Act = actId, Waves = {}, T0 = os.clock() }
	_G.BotLog[#_G.BotLog + 1] = log
	local ok, err = RS.StartMatch:InvokeServer(mode, actId)
	if not ok then log.Error = err log.Done = true return end
	local t0 = os.clock()
	while RS:GetAttribute("State") ~= "Intermission" and os.clock() - t0 < 30 do task.wait(0.5) end
	task.wait(1)
	local wp
	for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "Waypoints" then wp = d break end end
	local pts = {}
	for _, p in ipairs(wp:GetChildren()) do table.insert(pts, p) end
	table.sort(pts, function(a, b) return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0) end)
	local samples = {}
	for i = 1, #pts - 1 do
		local a, b = pts[i].Position, pts[i + 1].Position
		local n = math.max(1, math.floor((b - a).Magnitude / 2))
		for k = 0, n - 1 do table.insert(samples, a:Lerp(b, k / n)) end
	end
	local function flat(v) return Vector3.new(v.X, 0, v.Z) end
	local function distToPath(p)
		local best = math.huge
		for _, s in ipairs(samples) do best = math.min(best, (flat(s) - flat(p)).Magnitude) end
		return best
	end
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, s in ipairs(samples) do minX = math.min(minX, s.X) maxX = math.max(maxX, s.X) minZ = math.min(minZ, s.Z) maxZ = math.max(maxZ, s.Z) end
	local cands = {}
	for x = minX - 10, maxX + 10, 3 do
		for z = minZ - 10, maxZ + 10, 3 do
			local p = Vector3.new(x, 0.6, z)
			local d = distToPath(p)
			if d > 6.5 and d < 10 then
				local score = 0
				for _, s in ipairs(samples) do if (flat(s) - flat(p)).Magnitude < 14 then score += 1 end end
				table.insert(cands, { P = p, S = score })
			end
		end
	end
	table.sort(cands, function(a, b) return a.S > b.S end)
	local ok2, eq = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Equipped") or "[]")
	local team = {}
	for _, id in ipairs(ok2 and eq or {}) do if id ~= "" and Config.Units[id] then table.insert(team, id) end end
	log.Team = table.concat(team, ",")
	pcall(function() R.MatchVote:InvokeServer("Speed") task.wait(0.2) R.MatchVote:InvokeServer("Speed3") end)
	local placed, ci, lastWave = 0, 1, 0
	local counts, banned, ids = {}, {}, {}
	local maxUnits = opts.MaxUnits or Config.MaxUnitsPerPlayer or 12
	while true do
		local st = RS:GetAttribute("State")
		if st == "Victory" or st == "Defeat" or st == "Lobby" then log.Result = st break end
		if (RS:GetAttribute("GameSpeed") or 1) < 3 then pcall(function() R.MatchVote:InvokeServer("Speed3") end) end
		local w = RS:GetAttribute("Wave") or 0
		if w ~= lastWave then
			log.Waves[#log.Waves + 1] = { W = lastWave, Base = RS:GetAttribute("BaseHealth"), Cash = player:GetAttribute("Cash"), Units = placed }
			lastWave = w
		end
		local cash = player:GetAttribute("Cash") or 0
		if placed < maxUnits and #team > 0 then
			-- like a decent player: best damage-per-cash attacker you can afford; supports only after 4 attackers (max 2); no farms
			local pick, best
			local attackers = 0
			for id, n in pairs(counts) do if Config.Units[id].Levels[1].Damage then attackers += n end end
			for _, id in ipairs(team) do
				local def = Config.Units[id]
				local L = def.Levels[1]
				if cash >= def.Cost and not banned[id] then
					local score
					if L.Damage then
						local hits = (L.AttackType == "Multi" and (L.Targets or 3)) or (L.AttackType == "Chain" and (L.ChainCount or 2)) or (L.AttackType == "Cone" and 3) or (L.AttackType == "Splash" and 3) or (L.AttackType == "Line" and 3) or 1
						score = (L.Damage / math.max(L.Cooldown or 1, 0.1)) * hits / def.Cost
						score = score / (1 + (counts[id] or 0) * 0.15) -- a little variety
						if placed >= 8 then score *= def.Cost end -- slots are scarce late: raw damage wins
						if placed < 4 then score = 1 / def.Cost end -- opening: as many cheap attackers as possible
					elseif L.Buff and attackers >= 4 and (counts[id] or 0) < 2 then
						score = 0.0001
					end
					if score and (not best or score > best) then pick, best = id, score end
				end
			end
			if pick then
				while ci <= #cands do
					local ok3, res = R.PlaceUnit:InvokeServer(pick, cands[ci].P)
					if ok3 then
						placed += 1 counts[pick] = (counts[pick] or 0) + 1
						table.insert(ids, res)
						-- build a board first, then let auto-upgrade spend the cash
						if placed == (opts.UpgradeAfter or 6) then
							for _, id2 in ipairs(ids) do R.SetAutoUpgrade:InvokeServer(id2, true) end
						elseif placed > (opts.UpgradeAfter or 6) then
							R.SetAutoUpgrade:InvokeServer(res, true)
						end
						ci += 1
						break
					elseif type(res) == "string" and res:find("banned") then banned[pick] = true break
					elseif res == "Not enough cash" or (type(res) == "string" and res:find("limit")) then break
					else ci += 1 end
				end
			end
		end
		task.wait(0.4)
	end
	log.Wave = RS:GetAttribute("Wave")
	log.Base = RS:GetAttribute("BaseHealth")
	log.Secs = math.floor(os.clock() - log.T0)
	task.wait(1)
	pcall(function() R.PostMatchChoice:InvokeServer("Lobby") end)
	log.Done = true
end
_G.BotSummary = function()
	local out = {}
	for _, l in ipairs(_G.BotLog) do
		local lw = l.Waves[#l.Waves]
		table.insert(out, ("%s %s [%s] -> %s wave %s base %s (%ss)%s"):format(l.Mode, tostring(l.Act), tostring(l.Team), tostring(l.Result), tostring(l.Wave or (lw and lw.W)),
			tostring(l.Base), tostring(l.Secs), l.Error and (" ERR " .. l.Error) or ""))
	end
	return table.concat(out, "\n")
end
_G.RunQueue = function(list)
	_G.QueueDone = false
	for _, job in ipairs(list) do
		_G.RunBot(job[1], job[2], job[3])
		task.wait(4)
		local t0 = os.clock()
		while game.ReplicatedStorage:GetAttribute("State") ~= "Lobby" and os.clock() - t0 < 30 do task.wait(1) end
		task.wait(2)
	end
	_G.QueueDone = true
end
return "bot ready"
