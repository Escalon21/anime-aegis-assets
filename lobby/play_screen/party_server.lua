---------------------------------------------------------------- Parties (Play screen UI, replaces the physical Battle Gates)
-- Every player who opens the Play screen leads a party of 1. They can invite others, or join someone
-- else's open party. The host picks a mode on the Play screen -> short countdown -> LobbyService.OnLaunch.
local PARTY_MAX = GATE_MAX
local PARTY_COUNTDOWN = 6   -- seconds when there are several players (time for the others to see it)
local SOLO_COUNTDOWN = 3
local PartyRemote = Instance.new("RemoteFunction")
PartyRemote.Name = "Party"
PartyRemote.Parent = ReplicatedStorage
local PartyUpdate = Instance.new("RemoteEvent")
PartyUpdate.Name = "PartyUpdate"
PartyUpdate.Parent = ReplicatedStorage
local PartyInvite = Instance.new("RemoteEvent")
PartyInvite.Name = "PartyInvite"
PartyInvite.Parent = ReplicatedStorage

local parties = {}  -- host Player -> party
local memberOf = {} -- Player -> party

local function modeLabel(party)
	if party.Mode == "Story" and party.Act then return "Story - " .. party.Act.Name end
	if party.Mode == "Infinite" then return "Infinite Mode" end
	if party.Mode == "Aegis" then return "Aegis Mode" end
	return "Choosing a mode"
end
local function snapshot(party)
	local ids, names = {}, {}
	for _, m in ipairs(party.Members) do
		table.insert(ids, m.UserId)
		table.insert(names, m.DisplayName)
	end
	return { Host = party.Host.UserId, HostName = party.Host.DisplayName, Members = ids, Names = names, Max = PARTY_MAX,
		Mode = party.Mode, ActId = party.Act and party.Act.Id, Label = modeLabel(party),
		Countdown = party.Countdown and math.ceil(party.Countdown) or nil }
end
local function push(party)
	local snap = snapshot(party)
	for _, m in ipairs(party.Members) do PartyUpdate:FireClient(m, snap) end
end

local function ensureParty(player)
	local party = memberOf[player]
	if party then return party end
	party = { Host = player, Members = { player }, Invited = {} }
	parties[player] = party
	memberOf[player] = party
	GateHostRemote:FireClient(player) -- (the tutorial listens for this: "you are ready to pick a mode")
	push(party)
	return party
end

local function leave(player, reason)
	local party = memberOf[player]
	if not party then return end
	memberOf[player] = nil
	local i = table.find(party.Members, player)
	if i then table.remove(party.Members, i) end
	if player.Parent then PartyUpdate:FireClient(player, nil) end
	if party.Host == player then
		-- the host left: the next member takes over (keeps the group together)
		parties[player] = nil
		local nextHost = party.Members[1]
		if nextHost then
			party.Host = nextHost
			party.Mode, party.Act, party.Countdown = nil, nil, nil
			parties[nextHost] = party
			push(party)
			PartyInvite:FireClient(nextHost, { Notice = (reason or (player.DisplayName .. " left")) .. " - you are the party leader now" })
		end
	else
		party.Countdown = nil -- someone left: stop an automatic start
		push(party)
	end
end

local function join(player, host, needInvite)
	local party = host and parties[host]
	if not party then return false, "That party doesn't exist anymore" end
	if party == memberOf[player] then return true end
	if needInvite and not party.Invited[player] then return false, "You need an invite for that party" end
	if #party.Members >= PARTY_MAX then return false, "That party is full" end
	if party.Countdown then return false, "That party is already starting" end
	if player:GetAttribute("InMatch") then return false, "Finish your battle first" end
	leave(player)
	table.insert(party.Members, player)
	memberOf[player] = party
	party.Invited[player] = nil
	push(party)
	return true
end

PartyRemote.OnServerInvoke = function(player, action, arg)
	if LobbyService.IsBattleServer then return false, "No parties in a battle server" end
	if action == "Open" then
		return true, snapshot(ensureParty(player))
	elseif action == "Leave" then
		leave(player)
		return true, snapshot(ensureParty(player)) -- you get your own party of 1 again
	elseif action == "Invite" then
		local target = typeof(arg) == "Instance" and arg:IsA("Player") and arg or nil
		local party = ensureParty(player)
		if not target or target == player or not target.Parent then return false, "Player not found" end
		if party.Host ~= player then return false, "Only the party leader can invite" end
		if memberOf[target] == party then return false, target.DisplayName .. " is already in your party" end
		if #party.Members >= PARTY_MAX then return false, "Your party is full" end
		if target:GetAttribute("InMatch") then return false, target.DisplayName .. " is in a battle" end
		party.Invited[target] = true
		PartyInvite:FireClient(target, { Host = player.UserId, Name = player.DisplayName, Label = modeLabel(party) })
		return true
	elseif action == "Accept" or action == "Join" then
		local host = typeof(arg) == "number" and Players:GetPlayerByUserId(arg) or nil
		return join(player, host, false) -- parties in the same server are open; invites just point you to one
	elseif action == "List" then
		local list = {}
		for host, party in pairs(parties) do
			if host ~= player and memberOf[player] ~= party and #party.Members < PARTY_MAX and not party.Countdown and not host:GetAttribute("InMatch") then
				table.insert(list, { Host = host.UserId, Name = host.DisplayName, Count = #party.Members, Max = PARTY_MAX, Label = modeLabel(party) })
			end
		end
		table.sort(list, function(a, b) return a.Count > b.Count end)
		return true, list
	elseif action == "Players" then
		local list = {}
		local party = memberOf[player]
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and not (party and memberOf[p] == party) then
				table.insert(list, { UserId = p.UserId, Name = p.DisplayName, InMatch = p:GetAttribute("InMatch") == true,
					Invited = party and party.Invited[p] == true or false, Player = p })
			end
		end
		return true, list
	elseif action == "Cancel" then
		local party = memberOf[player]
		if party and party.Host == player then party.Countdown = nil push(party) end
		return true
	end
	return false, "Unknown action"
end

-- Called by the StartMatch remote: the party leader picks a mode
function LobbyService.ChooseMode(player, mode, actId)
	if ReplicatedStorage:GetAttribute("State") ~= "Lobby" then return false, "A battle is already running - try again soon" end
	local party = ensureParty(player)
	if party.Host ~= player then return false, "Only the party leader can pick the mode" end
	local profile = DataManager:GetProfile(player)
	if not profile then return false, "Data not loaded" end
	if mode == "Story" then
		if typeof(actId) ~= "string" then return false, "Invalid act" end
		local act = Config.GetAct(actId)
		if not act then return false, "Act not found" end
		if act.RequiresAct and not profile.Data.ClearedActs[act.RequiresAct] then
			return false, "Clear " .. act.RequiresAct .. " first!"
		end
		party.Mode, party.Act = "Story", act
	elseif mode == "Infinite" then
		party.Mode, party.Act = "Infinite", nil
	elseif mode == "Aegis" then
		party.Mode, party.Act = "Aegis", nil
	else
		return false, "Invalid mode"
	end
	party.Countdown = #party.Members > 1 and PARTY_COUNTDOWN or SOLO_COUNTDOWN
	push(party)
	return true
end

-- old "walk into a gate" remote: kept so nothing breaks; it just makes sure you have a party
GoToGateRemote.OnServerInvoke = function(player)
	ensureParty(player)
	return true
end

local function updateParties(dt)
	local lobbyOpen = ReplicatedStorage:GetAttribute("State") == "Lobby"
	local list = {}
	for host, party in pairs(parties) do table.insert(list, { host, party }) end
	for _, hp in ipairs(list) do
		local host, party = hp[1], hp[2]
		-- drop anyone who left the server or went into a battle
		for i = #party.Members, 1, -1 do
			local m = party.Members[i]
			if not m.Parent or m:GetAttribute("InMatch") then leave(m) end
		end
		if party.Countdown and parties[host] == party then
			if not lobbyOpen then
				party.Countdown = nil
				push(party)
			else
				local before = math.ceil(party.Countdown)
				party.Countdown -= dt
				if party.Countdown <= 0 then
					local match = { Mode = party.Mode, Act = party.Act, Party = table.clone(party.Members) }
					for _, m in ipairs(party.Members) do
						memberOf[m] = nil
						PartyUpdate:FireClient(m, nil)
					end
					parties[host] = nil
					if LobbyService.OnLaunch then LobbyService.OnLaunch(match) end
				elseif math.ceil(party.Countdown) ~= before then
					push(party)
				end
			end
		end
	end
end
Players.PlayerRemoving:Connect(function(p) leave(p, p.DisplayName .. " left the game") end)

