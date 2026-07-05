--!strict
--[[
	CloudFX
	═══════
	All the feel, rebuilt for the endless following world:
	  • REACTIVE COLOUR TRAIL — soft glowing splats dropped on the clouds as you run,
	    hue cycling with movement, fading behind you. Works with a moving floor and
	    reads as "the clouds change colour as you move."
	  • A SKY ORB that follows you (never left behind or cut off).
	  • Speed lines + FOV kick scaled to momentum/boost.
	  • HUD: Speed / Rings / live velocity, plus milestone celebrations.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
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
local milestoneSound = makeSound(Config.Sounds.Milestone)

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
	l.TextStrokeTransparency = 0.35
	l.TextSize = textSize
	l.Text = ""
	l.Parent = gui
	return l
end

local speedLabel = label(UDim2.fromScale(0.5, 0.05), UDim2.fromScale(0.7, 0.08), 34, Color3.fromRGB(255, 255, 255))
local ringsLabel = label(UDim2.fromScale(0.5, 0.13), UDim2.fromScale(0.7, 0.05), 22, Color3.fromRGB(255, 210, 64))
local velLabel   = label(UDim2.fromScale(0.5, 0.9),  UDim2.fromScale(0.7, 0.06), 20, Color3.fromRGB(190, 220, 255))
local announce   = label(UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.9, 0.15), 58, Color3.fromRGB(255, 255, 255))
announce.AnchorPoint = Vector2.new(0.5, 0.5)
announce.TextTransparency = 1

local function refreshHUD()
	speedLabel.Text = "SPEED  " .. (player:GetAttribute("Speed") or 0)
	ringsLabel.Text = "◍ " .. (player:GetAttribute("Coins") or 0) .. " rings"
end
player:GetAttributeChangedSignal("Speed"):Connect(refreshHUD)
player:GetAttributeChangedSignal("Coins"):Connect(refreshHUD)
refreshHUD()

local function bigAnnounce(text: string, color: Color3)
	announce.Text = text
	announce.TextColor3 = color
	announce.TextTransparency = 0
	announce.TextSize = 58
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < 1.3 do
			local a = (os.clock() - start) / 1.3
			announce.TextTransparency = a
			announce.TextSize = 58 + a * 46
			RunService.RenderStepped:Wait()
		end
		announce.TextTransparency = 1
	end)
end

-- ════════════════════════════════════════════════════════════
--  SKY ORB (client-side; follows the player)
-- ════════════════════════════════════════════════════════════
local orb = Instance.new("Part")
orb.Name = "SkyOrb"
orb.Shape = Enum.PartType.Ball
orb.Anchored = true
orb.CanCollide = false
orb.CanQuery = false
orb.CastShadow = false
orb.Material = Enum.Material.SmoothPlastic
orb.Color = Config.OrbColor
orb.Size = Vector3.new(Config.OrbSize, Config.OrbSize, Config.OrbSize)
orb.Parent = Workspace

-- ════════════════════════════════════════════════════════════
--  PARTICLE BURST (ring collect)
-- ════════════════════════════════════════════════════════════
local function burst(position: Vector3, color: Color3, amount: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
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
	Debris:AddItem(p, 1)
end

-- ════════════════════════════════════════════════════════════
--  REACTIVE COLOUR TRAIL
-- ════════════════════════════════════════════════════════════
local splats: { BasePart } = {}
local splatAccum = 0
local hue = 0
local lastTrailPos: Vector3? = nil

local function dropSplat(x: number, z: number, runSpeed: number)
	local frac = math.clamp(runSpeed / Config.MaxTopSpeed, 0, 1)
	local size = Config.SplatBaseSize + frac * Config.SplatSpeedSize
	local s = Instance.new("Part")
	s.Shape = Enum.PartType.Cylinder
	s.Anchored = true
	s.CanCollide = false
	s.CanQuery = false
	s.CastShadow = false
	s.Material = Enum.Material.Neon
	s.Color = Color3.fromHSV(hue % 1, Config.SplatSaturation, Config.SplatValue)
	s.Size = Vector3.new(0.4, size, size)
	s.CFrame = CFrame.new(x, Config.GroundY + 0.08, z) * CFrame.Angles(0, 0, math.rad(90))
	s.Transparency = 0.25
	s.Parent = Workspace

	TweenService:Create(s, TweenInfo.new(Config.SplatLife, Enum.EasingStyle.Quad), {
		Transparency = 1,
		Size = Vector3.new(0.4, size * 1.7, size * 1.7),
	}):Play()
	Debris:AddItem(s, Config.SplatLife + 0.1)

	table.insert(splats, s)
	if #splats > Config.MaxSplats then
		local old = table.remove(splats, 1)
		if old then old:Destroy() end
	end
end

-- ════════════════════════════════════════════════════════════
--  SPEED LINES
-- ════════════════════════════════════════════════════════════
local speedEmitter: ParticleEmitter? = nil
local function ensureSpeedEmitter(hrp: BasePart)
	if speedEmitter and speedEmitter.Parent == hrp then return end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	pe.Transparency = NumberSequence.new(0.5, 1)
	pe.Lifetime = NumberRange.new(0.18, 0.32)
	pe.Rate = 0
	pe.Speed = NumberRange.new(0)
	pe.Size = NumberSequence.new(2, 0.2)
	pe.LightEmission = 0.4
	pe.Parent = hrp
	speedEmitter = pe
end

-- ════════════════════════════════════════════════════════════
--  RING SPIN (tagged rings)
-- ════════════════════════════════════════════════════════════
local spinRings: { [BasePart]: boolean } = {}
for _, r in CollectionService:GetTagged("CloudRing") do
	if r:IsA("BasePart") then spinRings[r] = true end
end
CollectionService:GetInstanceAddedSignal("CloudRing"):Connect(function(r)
	if r:IsA("BasePart") then spinRings[r] = true end
end)
CollectionService:GetInstanceRemovedSignal("CloudRing"):Connect(function(r)
	spinRings[r :: BasePart] = nil
end)

-- ════════════════════════════════════════════════════════════
--  EVENTS
-- ════════════════════════════════════════════════════════════
Net.RingCollected.OnClientEvent:Connect(function(dataIn)
	play(ringSound, 0.5, 1 + math.random() * 0.1)
	burst(dataIn.position, Color3.fromRGB(255, 210, 64), 16)
end)

Net.Milestone.OnClientEvent:Connect(function(dataIn)
	play(milestoneSound, 0.8)
	bigAnnounce(tostring(dataIn.label) .. "!", Color3.fromRGB(140, 230, 255))
end)

local lastBoosting = false

-- ════════════════════════════════════════════════════════════
--  RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
	camera = camera or Workspace.CurrentCamera
	if not camera then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local runSpeed = ClientState.runSpeed

	-- Sky orb follows + bobs.
	if hrp then
		local bob = math.sin(os.clock() * Config.OrbBobSpeed) * Config.OrbBobAmplitude
		orb.CFrame = CFrame.new(hrp.Position + Config.OrbOffset + Vector3.new(0, bob, 0))
	end

	-- Colour trail.
	if hrp then
		local pos = hrp.Position
		if lastTrailPos then
			local d = Vector2.new(pos.X - lastTrailPos.X, pos.Z - lastTrailPos.Z).Magnitude
			hue += d * Config.HuePerStud
			splatAccum += d
			while splatAccum >= Config.SplatSpacing do
				splatAccum -= Config.SplatSpacing
				dropSplat(pos.X, pos.Z, runSpeed)
			end
		end
		lastTrailPos = pos
	end

	-- Ring spin.
	for ring in spinRings do
		if ring.Parent then
			ring.CFrame = ring.CFrame * CFrame.Angles(0, dt * 3, 0)
		else
			spinRings[ring] = nil
		end
	end

	-- Speed lines.
	if hrp then
		ensureSpeedEmitter(hrp)
		if speedEmitter then
			local frac = math.clamp(runSpeed / math.max(ClientState.topSpeed, 1), 0, 1)
			speedEmitter.Rate = frac > 0.55 and (frac - 0.55) * 140 or 0
		end
	end

	-- FOV from speed + boost.
	local sf = math.clamp(runSpeed / Config.MaxTopSpeed, 0, 1)
	local targetFov = Config.BaseFov + sf * Config.SpeedFovMax + (ClientState.boosting and Config.BoostFovKick or 0)
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 6)

	if ClientState.boosting and not lastBoosting then
		play(boostSound, 0.7)
	end
	lastBoosting = ClientState.boosting

	velLabel.Text = string.format("velocity  %d", math.floor(runSpeed))
end)
