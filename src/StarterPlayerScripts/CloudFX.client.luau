--!strict
--[[
	CloudFX
	═══════
	All the feel:
	  • REACTIVE CLOUD FLOOR — tiles near you bloom into color (hue cycles as you
	    move) and fade back to white behind you. Bounded to a small neighborhood
	    around the player so it's cheap on mobile.
	  • Speed lines + FOV kick that scale with your momentum / boost.
	  • HUD: Speed stat, Rings, live velocity.
	  • Ring spin + collect burst; gate-open flash.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local ClientState = require(ReplicatedStorage:WaitForChild("ClientState"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
--  SOUND
-- ════════════════════════════════════════════════════════════
local function makeSound(id: string): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Parent = SoundService
	return s
end
local ringSound = makeSound(Config.Sounds.Ring)
local boostSound = makeSound(Config.Sounds.Boost)
local gateSound = makeSound(Config.Sounds.Gate)

local function play(sound: Sound, volume: number, pitch: number?)
	if sound.SoundId == "" or sound.SoundId == "rbxassetid://0" then return end
	sound.Volume = volume
	sound.PlaybackSpeed = pitch or 1
	sound:Play()
end

-- ════════════════════════════════════════════════════════════
--  HUD
-- ════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "CloudRushHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(pos: UDim2, size: UDim2, textSize: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Font = Enum.Font.GothamBlack
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l.TextSize = textSize
	l.Text = ""
	l.Parent = gui
	return l
end

local speedLabel = label(UDim2.fromScale(0.5, 0.05), UDim2.fromScale(0.7, 0.08), 34, Color3.fromRGB(255, 255, 255))
local ringsLabel = label(UDim2.fromScale(0.5, 0.13), UDim2.fromScale(0.7, 0.05), 22, Color3.fromRGB(255, 216, 74))
local velLabel   = label(UDim2.fromScale(0.5, 0.9),  UDim2.fromScale(0.7, 0.06), 20, Color3.fromRGB(190, 220, 255))
local announce   = label(UDim2.fromScale(0.5, 0.4),  UDim2.fromScale(0.9, 0.15), 60, Color3.fromRGB(255, 255, 255))
announce.AnchorPoint = Vector2.new(0.5, 0.5)
announce.TextTransparency = 1

local function refreshHUD()
	local sp = player:GetAttribute("Speed") or 0
	local coins = player:GetAttribute("Coins") or 0
	speedLabel.Text = "SPEED  " .. sp
	ringsLabel.Text = "◍ " .. coins .. " rings"
end
player:GetAttributeChangedSignal("Speed"):Connect(refreshHUD)
player:GetAttributeChangedSignal("Coins"):Connect(refreshHUD)
refreshHUD()

local function bigAnnounce(text: string, color: Color3)
	announce.Text = text
	announce.TextColor3 = color
	announce.TextTransparency = 0
	announce.TextSize = 60
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < 1.1 do
			local a = (os.clock() - start) / 1.1
			announce.TextTransparency = a
			announce.TextSize = 60 + a * 40
			RunService.RenderStepped:Wait()
		end
		announce.TextTransparency = 1
	end)
end

-- ════════════════════════════════════════════════════════════
--  PARTICLE BURST
-- ════════════════════════════════════════════════════════════
local function burst(position: Vector3, color: Color3, amount: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = Workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Speed = NumberRange.new(10, 22)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(1.2)
	pe.LightEmission = 0.7
	pe.Parent = p
	pe:Emit(amount)

	task.delay(0.9, function()
		p:Destroy()
	end)
end

-- ════════════════════════════════════════════════════════════
--  REACTIVE CLOUD FLOOR
-- ════════════════════════════════════════════════════════════
local tileDict: { [string]: BasePart } = {}

local function registerTile(tile: Instance)
	if not tile:IsA("BasePart") then return end
	local i = tile:GetAttribute("GX")
	local j = tile:GetAttribute("GZ")
	if typeof(i) == "number" and typeof(j) == "number" then
		tileDict[i .. "_" .. j] = tile
	end
end

task.spawn(function()
	local world = Workspace:WaitForChild("CloudWorld")
	local floor = world:WaitForChild("Floor")
	for _, t in floor:GetChildren() do
		registerTile(t)
	end
	floor.ChildAdded:Connect(function(t)
		task.wait()
		registerTile(t)
	end)
end)

-- Active colored tiles → { color, expire }
type ActiveTile = { color: Color3, expire: number }
local active: { [BasePart]: ActiveTile } = {}
local hue = 0
local base = Config.BaseTileColor

local function updateReactiveFloor(dt: number, runSpeed: number)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local now = os.clock()

	if hrp then
		-- Hue drifts with how fast you're moving.
		hue = (hue + runSpeed * dt * Config.HuePerStud) % 1
		local target = Color3.fromHSV(hue, Config.TileSaturation, Config.TileValue)

		local pos = hrp.Position
		local ci, cj = Config.worldToCell(pos.X, pos.Z)
		local r = Config.BloomRadiusCells
		for di = -r, r do
			for dj = -r, r do
				local tile = tileDict[(ci + di) .. "_" .. (cj + dj)]
				if tile then
					active[tile] = { color = target, expire = now + Config.ColorFadeTime }
				end
			end
		end
	end

	-- Fade/color pass over the bounded active set.
	for tile, info in active do
		local remaining = info.expire - now
		if remaining <= 0 then
			tile.Color = base
			active[tile] = nil
		else
			local a = remaining / Config.ColorFadeTime
			tile.Color = base:Lerp(info.color, a)
		end
	end
end

-- ════════════════════════════════════════════════════════════
--  RING SPIN  (local visual)
-- ════════════════════════════════════════════════════════════
local ringsFolder: Instance? = nil
task.spawn(function()
	local world = Workspace:WaitForChild("CloudWorld")
	ringsFolder = world:WaitForChild("Rings")
end)

-- ════════════════════════════════════════════════════════════
--  SPEED LINES  (local wind streaks when moving fast)
-- ════════════════════════════════════════════════════════════
local speedEmitter: ParticleEmitter? = nil
local function ensureSpeedEmitter()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		speedEmitter = nil
		return
	end
	if speedEmitter and speedEmitter.Parent == hrp then return end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	pe.Transparency = NumberSequence.new(0.4, 1)
	pe.Lifetime = NumberRange.new(0.2, 0.35)
	pe.Rate = 0
	pe.Speed = NumberRange.new(0)
	pe.Size = NumberSequence.new(2.2, 0.2)
	pe.LightEmission = 0.5
	pe.Parent = hrp
	speedEmitter = pe
end

-- ════════════════════════════════════════════════════════════
--  EVENTS
-- ════════════════════════════════════════════════════════════
Net.RingCollected.OnClientEvent:Connect(function(data)
	play(ringSound, 0.5, 1 + math.random() * 0.1)
	burst(data.position, Color3.fromRGB(255, 216, 74), 16)
	local ping = os.clock()
	ringsLabel.TextSize = 30
	task.delay(0.12, function()
		if os.clock() - ping >= 0.1 then ringsLabel.TextSize = 22 end
	end)
end)

Net.GateOpened.OnClientEvent:Connect(function(data)
	play(gateSound, 0.8)
	bigAnnounce(tostring(data.label):gsub("Gate_", "") .. " OPEN!", Color3.fromRGB(120, 255, 170))
	if typeof(data.position) == "Vector3" then
		burst(data.position, Color3.fromRGB(120, 255, 170), 40)
	end
end)

-- Boost feedback (watch the shared state flip).
local lastBoosting = false

-- ════════════════════════════════════════════════════════════
--  RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
	camera = camera or Workspace.CurrentCamera
	if not camera then return end

	local runSpeed = ClientState.runSpeed
	local topSpeed = math.max(ClientState.topSpeed, 1)

	updateReactiveFloor(dt, runSpeed)

	-- Spin rings.
	if ringsFolder then
		for _, ring in ringsFolder:GetChildren() do
			if ring:IsA("BasePart") then
				ring.CFrame = ring.CFrame * CFrame.Angles(0, dt * 3, 0)
			end
		end
	end

	-- Speed lines scale with velocity.
	ensureSpeedEmitter()
	if speedEmitter then
		local frac = math.clamp(runSpeed / topSpeed, 0, 1)
		speedEmitter.Rate = frac > 0.5 and (frac - 0.5) * 120 or 0
	end

	-- FOV kick from speed + boost.
	local frac = math.clamp(runSpeed / Config.MaxTopSpeed, 0, 1)
	local targetFov = Config.BaseFov + frac * 22 + (ClientState.boosting and Config.BoostFovKick or 0)
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 6)

	-- Boost sound edge-trigger.
	if ClientState.boosting and not lastBoosting then
		play(boostSound, 0.7)
	end
	lastBoosting = ClientState.boosting

	-- Live velocity readout.
	velLabel.Text = string.format("velocity  %d", math.floor(runSpeed))
end)
