--!strict
--[[
	CloudRushServer
	═══════════════
	Server-authoritative game state for the endless sky.

	Per player we own:
	  • a Ground disc that FOLLOWS them  → they can never fall off
	  • a field of cloud PUFFS that WRAP around them (treadmill) → endless motion
	  • a field of RINGS that wrap + can be collected → +1 Speed
	Plus: running distance → +1 Speed, speed milestones, DataStore persistence.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local root = WorldBuilder.build()

-- ════════════════════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════════════════════
type PData = { Speed: number, Coins: number, BestSpeed: number }
type PState = {
	folder: Folder,
	ground: Part,
	puffs: { Model },
	rings: { Part },
	lastPos: Vector3?,
	distAccum: number,
	milestonesHit: { [number]: boolean },
}

local store = DataStoreService:GetDataStore("CloudRush_v2")
local data: { [Player]: PData } = {}
local state: { [Player]: PState } = {}

-- ════════════════════════════════════════════════════════════
--  STATS
-- ════════════════════════════════════════════════════════════
local function syncStats(player: Player)
	local d = data[player]
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local speed = ls:FindFirstChild("Speed") :: IntValue?
	if not speed then
		speed = Instance.new("IntValue")
		speed.Name = "Speed"
		speed.Parent = ls
	end
	local coins = ls:FindFirstChild("Rings") :: IntValue?
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Rings"
		coins.Parent = ls
	end
	speed.Value = d.Speed
	coins.Value = d.Coins
	player:SetAttribute("Speed", d.Speed)
	player:SetAttribute("Coins", d.Coins)
end

-- ════════════════════════════════════════════════════════════
--  MILESTONES
-- ════════════════════════════════════════════════════════════
local function checkMilestones(player: Player)
	local d = data[player]
	local st = state[player]
	if not d or not st then return end
	for i, m in Config.SpeedMilestones do
		if not st.milestonesHit[i] and d.Speed >= m.speed then
			st.milestonesHit[i] = true
			Net.Milestone:FireClient(player, { label = m.label, speed = m.speed })
		end
	end
end

local function awardSpeed(player: Player, amount: number)
	local d = data[player]
	if not d then return end
	d.Speed += amount
	if d.Speed > d.BestSpeed then d.BestSpeed = d.Speed end
	player:SetAttribute("Speed", d.Speed)
	local ls = player:FindFirstChild("leaderstats")
	local speed = ls and ls:FindFirstChild("Speed") :: IntValue?
	if speed then speed.Value = d.Speed end
	checkMilestones(player)
end

-- ════════════════════════════════════════════════════════════
--  RINGS
-- ════════════════════════════════════════════════════════════
local function collectRing(player: Player, ring: Part)
	if not ring.CanTouch then return end
	local d = data[player]
	if not d then return end

	ring.CanTouch = false
	ring.Transparency = 1

	awardSpeed(player, Config.SpeedPerRing)
	d.Coins += Config.CoinsPerRing
	player:SetAttribute("Coins", d.Coins)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Rings") :: IntValue?
	if coins then coins.Value = d.Coins end

	Net.RingCollected:FireClient(player, {
		position = ring.Position,
		speed = d.Speed,
		rings = d.Coins,
	})

	task.delay(2.5, function()
		if ring and ring.Parent then
			ring.Transparency = 0
			ring.CanTouch = true
		end
	end)
end

-- ════════════════════════════════════════════════════════════
--  PER-PLAYER WORLD
-- ════════════════════════════════════════════════════════════
local function buildPlayerWorld(player: Player): PState
	local folder = Instance.new("Folder")
	folder.Name = "World_" .. player.UserId
	folder.Parent = root

	local ground = WorldBuilder.makeGround()
	ground.Parent = folder

	local puffs: { Model } = {}
	for _ = 1, Config.PuffClusters do
		local cluster = WorldBuilder.makePuffCluster()
		local x = math.random(-Config.FieldHalf, Config.FieldHalf)
		local z = math.random(-Config.FieldHalf, Config.FieldHalf)
		local y = math.random(Config.PuffMinY, Config.PuffMaxY)
		cluster:PivotTo(CFrame.new(x, y, z))
		cluster.Parent = folder
		table.insert(puffs, cluster)
	end

	local rings: { Part } = {}
	for _ = 1, Config.RingsPerPlayer do
		local x = math.random(-Config.RingFieldHalf, Config.RingFieldHalf)
		local z = math.random(-Config.RingFieldHalf, Config.RingFieldHalf)
		local ring = WorldBuilder.makeRing(Vector3.new(x, Config.GroundY + Config.RingFloatHeight, z))
		ring.Parent = folder
		CollectionService:AddTag(ring, "CloudRing")
		ring.Touched:Connect(function(hit)
			local character = hit.Parent
			local toucher = character and Players:GetPlayerFromCharacter(character)
			if toucher == player then
				collectRing(player, ring)
			end
		end)
		table.insert(rings, ring)
	end

	return {
		folder = folder,
		ground = ground,
		puffs = puffs,
		rings = rings,
		lastPos = nil,
		distAccum = 0,
		milestonesHit = {},
	}
end

-- Treadmill wrap: keep an item within ±half of the player on X/Z. Items stay
-- world-static (you move past them) and only teleport when they fall outside the
-- window — which, for puffs, is beyond the fog so the pop is hidden.
local function wrapItemXZ(px: number, pz: number, itemX: number, itemZ: number, half: number): (number, number, boolean)
	local nx, nz = itemX, itemZ
	local moved = false
	if itemX - px > half then nx = itemX - half * 2; moved = true
	elseif itemX - px < -half then nx = itemX + half * 2; moved = true end
	if itemZ - pz > half then nz = itemZ - half * 2; moved = true
	elseif itemZ - pz < -half then nz = itemZ + half * 2; moved = true end
	return nx, nz, moved
end

-- ════════════════════════════════════════════════════════════
--  SPAWN
-- ════════════════════════════════════════════════════════════
local function onCharacterAdded(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

	hum.UseJumpPower = true
	hum.JumpPower = Config.JumpPower

	-- Speed trail (server-made → all players see each other's streaks).
	if not hrp:FindFirstChild("TrailTop") then
		local a0 = Instance.new("Attachment"); a0.Name = "TrailTop"; a0.Position = Vector3.new(0, 1.4, 0); a0.Parent = hrp
		local a1 = Instance.new("Attachment"); a1.Name = "TrailBottom"; a1.Position = Vector3.new(0, -1.4, 0); a1.Parent = hrp
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.5
		trail.MinLength = 0.1
		trail.LightEmission = 0.5
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Transparency = NumberSequence.new(0.15, 1)
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 140, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 220)),
		})
		trail.Parent = hrp
	end

	local st = state[player]
	-- Small offset so players don't stack on the exact same point.
	local sx = math.random(-12, 12)
	local sz = math.random(-12, 12)
	task.wait(0.1)
	if st then
		WorldBuilder.moveGround(st.ground, sx, sz)
	end
	-- Spawn on the ground, facing a set direction (fixes "spawn faces the wrong way").
	local spawnPos = Vector3.new(sx, Config.GroundY + Config.SpawnHeight, sz)
	hrp.CFrame = CFrame.lookAt(spawnPos, spawnPos + Config.SpawnFacing)
	if st then
		st.lastPos = hrp.Position
		st.distAccum = 0
	end
end

-- ════════════════════════════════════════════════════════════
--  PERSISTENCE
-- ════════════════════════════════════════════════════════════
local function loadData(player: Player)
	local ok, result = pcall(function()
		return store:GetAsync("p_" .. player.UserId)
	end)
	local d: PData
	if ok and typeof(result) == "table" then
		d = { Speed = result.Speed or 0, Coins = result.Coins or 0, BestSpeed = result.BestSpeed or 0 }
	else
		d = { Speed = 0, Coins = 0, BestSpeed = 0 }
	end
	data[player] = d
end

local function saveData(player: Player)
	local d = data[player]
	if not d then return end
	pcall(function()
		store:SetAsync("p_" .. player.UserId, d)
	end)
end

local function onPlayerAdded(player: Player)
	loadData(player)
	state[player] = buildPlayerWorld(player)
	syncStats(player)

	-- Mark already-passed milestones so we don't re-announce old ones.
	local d = data[player]
	for i, m in Config.SpeedMilestones do
		if d.Speed >= m.speed then
			state[player].milestonesHit[i] = true
		end
	end

	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	saveData(player)
	local st = state[player]
	if st then st.folder:Destroy() end
	state[player] = nil
	data[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in Players:GetPlayers() do
	onPlayerAdded(p)
end

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		saveData(p)
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do
			saveData(p)
		end
	end
end)

-- ════════════════════════════════════════════════════════════
--  MAIN LOOP: follow ground, wrap clouds/rings, reward running
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	for player, st in state do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then continue end
		local pos = hrp.Position
		local px, pz = pos.X, pos.Z

		-- Ground follows (snapped so it never jitters). One part = cheap.
		local snap = Config.GroundFollowSnap
		WorldBuilder.moveGround(st.ground, math.round(px / snap) * snap, math.round(pz / snap) * snap)

		-- Cloud puffs wrap around the player (beyond fog → invisible pops).
		for _, puff in st.puffs do
			local pv = puff:GetPivot()
			local ip = pv.Position
			local nx, nz, moved = wrapItemXZ(px, pz, ip.X, ip.Z, Config.FieldHalf)
			if moved then
				puff:PivotTo(CFrame.new(nx, ip.Y, nz))
			end
		end

		-- Rings wrap too, staying near the player.
		for _, ring in st.rings do
			local rp = ring.Position
			local nx, nz, moved = wrapItemXZ(px, pz, rp.X, rp.Z, Config.RingFieldHalf)
			if moved then
				ring.Position = Vector3.new(nx, Config.GroundY + Config.RingFloatHeight, nz)
			end
		end

		-- Running grants Speed (keyboard-loop DNA).
		local lp = st.lastPos
		if lp then
			local delta = pos - lp
			st.distAccum += Vector2.new(delta.X, delta.Z).Magnitude
			while st.distAccum >= Config.StudsPerSpeed do
				st.distAccum -= Config.StudsPerSpeed
				awardSpeed(player, 1)
			end
		end
		st.lastPos = pos
	end
end)
