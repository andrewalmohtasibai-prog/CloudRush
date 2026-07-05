--!strict
--[[
	CloudRushServer
	═══════════════
	Server-authoritative game state for the endless sky.

	Per player we own:
	  • a Ground disc that FOLLOWS them  → they can never fall off
	  • a field of cloud PUFFS that WRAP around them → endless motion
	  • a field of RINGS that wrap + are collected by DISTANCE (never missed at speed)
	Plus: running distance → +1 Speed, milestones, DataStore persistence, Sonic jump.

	Perf: the ground follow + puff/ring wrap only run when the player crosses a grid
	cell (GroundFollowSnap), not every frame. Ring pickup + speed reward run every frame.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Sonic = require(ReplicatedStorage:WaitForChild("SonicPhysics"))
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
	cellX: number,
	cellZ: number,
	milestonesHit: { [number]: boolean },
}

local store = DataStoreService:GetDataStore("CloudRush_v2")
local data: { [Player]: PData } = {}
local state: { [Player]: PState } = {}

-- ════════════════════════════════════════════════════════════
--  STATS
-- ════════════════════════════════════════════════════════════
local function ensureStat(player: Player, name: string): IntValue
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local v = ls:FindFirstChild(name) :: IntValue?
	if not v then
		v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	return v
end

local function syncStats(player: Player)
	local d = data[player]
	if not d then return end
	ensureStat(player, "Speed").Value = d.Speed
	ensureStat(player, "Rings").Value = d.Coins
	player:SetAttribute("Speed", d.Speed)
	player:SetAttribute("Coins", d.Coins)
end

-- ════════════════════════════════════════════════════════════
--  MILESTONES + AWARD
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
	ensureStat(player, "Speed").Value = d.Speed
	checkMilestones(player)
end

-- ════════════════════════════════════════════════════════════
--  RINGS (distance-based pickup → never tunnels at speed)
-- ════════════════════════════════════════════════════════════
local function collectRing(player: Player, ring: Part)
	if not ring:GetAttribute("Available") then return end
	local d = data[player]
	if not d then return end

	ring:SetAttribute("Available", false)
	ring.Transparency = 1

	awardSpeed(player, Config.SpeedPerRing)
	d.Coins += Config.CoinsPerRing
	player:SetAttribute("Coins", d.Coins)
	ensureStat(player, "Rings").Value = d.Coins

	Net.RingCollected:FireClient(player, { position = ring.Position, speed = d.Speed, rings = d.Coins })

	task.delay(Config.RingRespawn, function()
		if ring and ring.Parent then
			ring.Transparency = 0
			ring:SetAttribute("Available", true)
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
		cluster:PivotTo(CFrame.new(
			math.random(-Config.FieldHalf, Config.FieldHalf),
			math.random(Config.PuffMinY, Config.PuffMaxY),
			math.random(-Config.FieldHalf, Config.FieldHalf)
		))
		cluster.Parent = folder
		table.insert(puffs, cluster)
	end

	local rings: { Part } = {}
	for _ = 1, Config.RingsPerPlayer do
		local ring = WorldBuilder.makeRing(Vector3.new(
			math.random(-Config.RingFieldHalf, Config.RingFieldHalf),
			Config.GroundY + Config.RingFloatHeight,
			math.random(-Config.RingFieldHalf, Config.RingFieldHalf)
		))
		ring.Parent = folder
		CollectionService:AddTag(ring, "CloudRing")
		table.insert(rings, ring)
	end

	return {
		folder = folder,
		ground = ground,
		puffs = puffs,
		rings = rings,
		lastPos = nil,
		distAccum = 0,
		cellX = math.huge,
		cellZ = math.huge,
		milestonesHit = {},
	}
end

-- Treadmill wrap: teleport an item to the far side when it falls outside ±half of
-- the player, so decor stays around you and pops happen beyond the fog.
local function wrapXZ(px: number, pz: number, ix: number, iz: number, half: number): (number, number, boolean)
	local nx, nz, moved = ix, iz, false
	if ix - px > half then nx = ix - half * 2; moved = true
	elseif ix - px < -half then nx = ix + half * 2; moved = true end
	if iz - pz > half then nz = iz - half * 2; moved = true
	elseif iz - pz < -half then nz = iz + half * 2; moved = true end
	return nx, nz, moved
end

-- ════════════════════════════════════════════════════════════
--  SPAWN
-- ════════════════════════════════════════════════════════════
local function addSpeedTrail(hrp: BasePart)
	if hrp:FindFirstChild("TrailTop") then return end
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

local function onCharacterAdded(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- Authentic Sonic jump: JumpPower from the guide's jump velocity, gravity set in
	-- the project file to the guide's gravity, giving a Sonic-shaped jump arc.
	hum.UseJumpPower = true
	hum.JumpPower = Sonic.JumpVelocity

	addSpeedTrail(hrp)

	local st = state[player]
	local sx = math.random(-12, 12)
	local sz = math.random(-12, 12)
	task.wait(0.1)
	if st then
		WorldBuilder.moveGround(st.ground, sx, sz)
		st.cellX, st.cellZ = math.huge, math.huge -- force a recentre next frame
	end
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
	if ok and typeof(result) == "table" then
		data[player] = { Speed = result.Speed or 0, Coins = result.Coins or 0, BestSpeed = result.BestSpeed or 0 }
	else
		data[player] = { Speed = 0, Coins = 0, BestSpeed = 0 }
	end
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

	local d = data[player]
	for i, m in Config.SpeedMilestones do
		if d.Speed >= m.speed then state[player].milestonesHit[i] = true end
	end

	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	if player.Character then onCharacterAdded(player, player.Character) end
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
for _, p in Players:GetPlayers() do onPlayerAdded(p) end

game:BindToClose(function()
	for _, p in Players:GetPlayers() do saveData(p) end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do saveData(p) end
	end
end)

-- ════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════════════════════════
local snap = Config.GroundFollowSnap
local pickupSq = Config.RingPickupRadius * Config.RingPickupRadius

RunService.Heartbeat:Connect(function()
	for player, st in state do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then continue end
		local pos = hrp.Position
		local px, pz = pos.X, pos.Z

		-- Ring pickup — every frame, by distance (never tunnels at high speed).
		for _, ring in st.rings do
			if ring:GetAttribute("Available") then
				local dx = ring.Position.X - px
				local dz = ring.Position.Z - pz
				local dy = ring.Position.Y - pos.Y
				if dx * dx + dy * dy + dz * dz <= pickupSq then
					collectRing(player, ring)
				end
			end
		end

		-- Running grants Speed.
		local lp = st.lastPos
		if lp then
			local dx = pos.X - lp.X
			local dz = pos.Z - lp.Z
			st.distAccum += math.sqrt(dx * dx + dz * dz)
			while st.distAccum >= Config.StudsPerSpeed do
				st.distAccum -= Config.StudsPerSpeed
				awardSpeed(player, 1)
			end
		end
		st.lastPos = pos

		-- Recentre ground + wrap decor ONLY when we cross a grid cell (perf).
		local cx = math.round(px / snap)
		local cz = math.round(pz / snap)
		if cx ~= st.cellX or cz ~= st.cellZ then
			st.cellX, st.cellZ = cx, cz
			WorldBuilder.moveGround(st.ground, cx * snap, cz * snap)

			for _, puff in st.puffs do
				local ip = puff:GetPivot().Position
				local nx, nz, moved = wrapXZ(px, pz, ip.X, ip.Z, Config.FieldHalf)
				if moved then puff:PivotTo(CFrame.new(nx, ip.Y, nz)) end
			end
			for _, ring in st.rings do
				local rp = ring.Position
				local nx, nz, moved = wrapXZ(px, pz, rp.X, rp.Z, Config.RingFieldHalf)
				if moved then ring.Position = Vector3.new(nx, Config.GroundY + Config.RingFloatHeight, nz) end
			end
		end
	end
end)
