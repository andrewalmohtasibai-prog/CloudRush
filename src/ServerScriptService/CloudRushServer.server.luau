--!strict
--[[
	CloudRushServer
	═══════════════
	Owns the game state:
	  • Builds the world (via WorldBuilder)
	  • Spawns players onto the clouds
	  • Rings → +1 Speed (keyboard-game loop), Sonic-flavored
	  • Running itself → +1 Speed every N studs (movement is rewarded)
	  • Speed gates open when the threshold is reached
	  • DataStore persistence (Speed / Coins / BestSpeed) so the number never resets
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local World = WorldBuilder.build()

-- ════════════════════════════════════════════════════════════
--  PLAYER DATA
-- ════════════════════════════════════════════════════════════
type PData = { Speed: number, Coins: number, BestSpeed: number }

local store = DataStoreService:GetDataStore("CloudRush_v1")
local data: { [Player]: PData } = {}
local lastPos: { [Player]: Vector3 } = {}
local distAccum: { [Player]: number } = {}

local function statsFolder(player: Player): Folder
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	return ls :: Folder
end

local function syncStats(player: Player)
	local d = data[player]
	if not d then return end
	local ls = statsFolder(player)
	local speed = ls:FindFirstChild("Speed") :: IntValue?
	if not speed then
		speed = Instance.new("IntValue")
		speed.Name = "Speed"
		speed.Parent = ls
	end
	local coins = ls:FindFirstChild("Coins") :: IntValue?
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = ls
	end
	speed.Value = d.Speed
	coins.Value = d.Coins
	player:SetAttribute("Speed", d.Speed)
	player:SetAttribute("Coins", d.Coins)
end

-- ════════════════════════════════════════════════════════════
--  SPEED GATES  (open globally when anyone crosses the threshold)
-- ════════════════════════════════════════════════════════════
local function openGate(gate: Model)
	if gate:GetAttribute("Opened") then return end
	gate:SetAttribute("Opened", true)

	for _, part in gate:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "Pane" then
				TweenService:Create(part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
			else
				part.Color = Color3.fromRGB(120, 255, 170)
			end
		end
	end

	local pane = gate:FindFirstChild("Pane") :: BasePart?
	Net.GateOpened:FireAllClients({
		label = gate.Name,
		position = pane and pane.Position or Vector3.zero,
	})
end

local function checkGates(player: Player)
	local d = data[player]
	if not d then return end
	for _, gate in World.gates:GetChildren() do
		if gate:IsA("Model") and not gate:GetAttribute("Opened") then
			local req = gate:GetAttribute("RequiredSpeed") :: number
			if d.Speed >= req then
				openGate(gate)
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════
--  AWARDING SPEED
-- ════════════════════════════════════════════════════════════
local function awardSpeed(player: Player, amount: number)
	local d = data[player]
	if not d then return end
	d.Speed += amount
	if d.Speed > d.BestSpeed then
		d.BestSpeed = d.Speed
	end
	player:SetAttribute("Speed", d.Speed)
	local ls = player:FindFirstChild("leaderstats")
	local speed = ls and ls:FindFirstChild("Speed") :: IntValue?
	if speed then speed.Value = d.Speed end
	checkGates(player)
end

-- ════════════════════════════════════════════════════════════
--  RINGS
-- ════════════════════════════════════════════════════════════
local function collectRing(player: Player, ring: BasePart)
	if not ring.CanTouch then return end
	local d = data[player]
	if not d then return end

	ring.CanTouch = false
	ring.Transparency = 1

	awardSpeed(player, Config.SpeedPerRing)
	d.Coins += Config.CoinsPerRing
	player:SetAttribute("Coins", d.Coins)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Coins") :: IntValue?
	if coins then coins.Value = d.Coins end

	Net.RingCollected:FireClient(player, {
		position = ring.Position,
		speed = d.Speed,
		rings = d.Coins,
	})

	task.delay(Config.RingRespawn, function()
		if ring and ring.Parent then
			ring.Transparency = 0
			ring.CanTouch = true
		end
	end)
end

for _, ring in World.rings:GetChildren() do
	if ring:IsA("BasePart") then
		ring.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				collectRing(player, ring)
			end
		end)
	end
end

-- ════════════════════════════════════════════════════════════
--  SPAWNING
-- ════════════════════════════════════════════════════════════
local function addSpeedTrail(hrp: BasePart)
	-- Created on the server so EVERY player sees each other's streaks (social flex).
	-- Trails only render while moving, so no toggling needed.
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = hrp
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.45
	trail.MinLength = 0.1
	trail.LightEmission = 0.6
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Transparency = NumberSequence.new(0.1, 1)
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

	hum.UseJumpPower = true
	hum.JumpPower = Config.JumpPower

	addSpeedTrail(hrp)

	task.wait(0.1)
	hrp.CFrame = CFrame.new(math.random(-20, 20), Config.FloorTopY + 5, math.random(-20, 20))
	lastPos[player] = hrp.Position
	distAccum[player] = 0
end

-- ════════════════════════════════════════════════════════════
--  PERSISTENCE
-- ════════════════════════════════════════════════════════════
local function loadData(player: Player)
	local key = "p_" .. player.UserId
	local ok, result = pcall(function()
		return store:GetAsync(key)
	end)
	local d: PData
	if ok and typeof(result) == "table" then
		d = {
			Speed = result.Speed or 0,
			Coins = result.Coins or 0,
			BestSpeed = result.BestSpeed or 0,
		}
	else
		d = { Speed = 0, Coins = 0, BestSpeed = 0 }
	end
	data[player] = d
	syncStats(player)
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
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	saveData(player)
	data[player] = nil
	lastPos[player] = nil
	distAccum[player] = nil
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

-- Autosave every 60s.
task.spawn(function()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do
			saveData(p)
		end
	end
end)

-- ════════════════════════════════════════════════════════════
--  MOVEMENT REWARD + ORB BOB
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	-- Running makes you permanently faster (keyboard-loop DNA).
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and data[player] then
			local lp = lastPos[player]
			if lp then
				local delta = hrp.Position - lp
				local movedXZ = Vector2.new(delta.X, delta.Z).Magnitude
				distAccum[player] = (distAccum[player] or 0) + movedXZ
				local per = Config.StudsPerSpeed
				while (distAccum[player] or 0) >= per do
					distAccum[player] = (distAccum[player] or 0) - per
					awardSpeed(player, 1)
				end
			end
			lastPos[player] = hrp.Position
		end
	end
end)

-- Gentle orb bob (one shared part, cheap).
local orb = World.orb
local baseY = orb.Position.Y
task.spawn(function()
	while orb and orb.Parent do
		local t = os.clock() * Config.OrbBobSpeed
		orb.Position = Vector3.new(orb.Position.X, baseY + math.sin(t) * Config.OrbBobAmplitude, orb.Position.Z)
		RunService.Heartbeat:Wait()
	end
end)
