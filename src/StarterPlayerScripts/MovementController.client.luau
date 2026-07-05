--!strict
--[[
	MovementController  (v4 — robust, Humanoid-native Sonic feel)
	═════════════════════════════════════════════════════════════
	Lesson learned: do NOT fight the Humanoid (no WalkSpeed=0 + LinearVelocity).
	Instead we KEEP the Humanoid in charge of movement / turning / animation /
	collision / jumping, and drive its WalkSpeed with the Sonic acceleration curve.

	Sonic feel we keep (constants from SonicPhysics.luau):
	  • Acceleration ramp — you speed up over time while holding a direction.
	  • Skid — pressing against your motion brakes hard.
	  • Friction / roll friction.
	  • Spindash — hold to charge (rev pitch ladders up), release to LAUNCH forward.
	  • Speed stat multiplies top speed.

	Trade-off (documented, revisit later): with the Humanoid model you stop when you
	release input (no free coasting). For a hold-forward runner this is fine; true
	glide/inertia would need a full custom physics character (a later milestone).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Sonic = require(ReplicatedStorage:WaitForChild("SonicPhysics"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local ClientState = require(ReplicatedStorage:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local controls
task.spawn(function()
	pcall(function()
		local ps = player:WaitForChild("PlayerScripts")
		controls = require(ps:WaitForChild("PlayerModule")):GetControls()
	end)
end)

local currentSpeed = 0
local charging = false
local chargeLevel = 0
local rolling = false
local launching = false
local launchDir = Vector3.new(0, 0, 1)
local launchUntil = 0

-- ── Spindash ────────────────────────────────────────────────
local function onSpindash(_, s: Enum.UserInputState)
	if s == Enum.UserInputState.Begin then
		charging = true
		chargeLevel = 0
	elseif s == Enum.UserInputState.End or s == Enum.UserInputState.Cancel then
		if charging then
			charging = false
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local grounded = hum and hum.FloorMaterial ~= Enum.Material.Air
			if grounded and hrp and chargeLevel > 0.15 then
				local mult = Config.getSpeedMultiplier(player:GetAttribute("Speed") or 0)
				currentSpeed = Sonic.spindashSpeed(chargeLevel) * math.sqrt(mult)
				local look = hrp.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				launchDir = (flat.Magnitude > 0.01) and flat.Unit or Vector3.new(0, 0, 1)
				launching = true
				launchUntil = os.clock() + 0.5
				ClientState.boosting = true
				task.delay(0.45, function() ClientState.boosting = false end)
				Net.Boosted:FireServer()
			end
			chargeLevel = 0
			ClientState.charging = false
			ClientState.chargeLevel = 0
		end
	end
	return Enum.ContextActionResult.Sink
end

-- ── Roll (hold) ─────────────────────────────────────────────
local function onRoll(_, s: Enum.UserInputState)
	if s == Enum.UserInputState.Begin then
		rolling = true
		ClientState.rolling = true
	elseif s == Enum.UserInputState.End or s == Enum.UserInputState.Cancel then
		rolling = false
		ClientState.rolling = false
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Spindash", onSpindash, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("Spindash", "CHARGE")
ContextActionService:SetPosition("Spindash", UDim2.new(1, -120, 0.55, 0))
ContextActionService:BindAction("Roll", onRoll, true, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("Roll", "ROLL")
ContextActionService:SetPosition("Roll", UDim2.new(1, -120, 0.72, 0))

-- ── Camera behind on spawn ──────────────────────────────────
player.CharacterAdded:Connect(function(char)
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
	currentSpeed = 0
	launching = false
	charging = false
	task.wait(0.25)
	local cam = Workspace.CurrentCamera
	if cam then
		local behind = hrp.Position - Config.SpawnFacing.Unit * 16 + Vector3.new(0, 6, 0)
		cam.CFrame = CFrame.lookAt(behind, hrp.Position + Vector3.new(0, 2, 0))
	end
end)

-- ── Helpers ─────────────────────────────────────────────────
local function moveToward(a: number, b: number, d: number): number
	if a < b then return math.min(a + d, b) else return math.max(a - d, b) end
end

local function inputMagnitude(hum: Humanoid): number
	if controls then
		local ok, mv = pcall(function() return controls:GetMoveVector() end)
		if ok and typeof(mv) == "Vector3" then return math.min(mv.Magnitude, 1) end
	end
	return hum.MoveDirection.Magnitude
end

-- ── Main loop ───────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then return end

	local speedStat = player:GetAttribute("Speed") or 0
	local mult = Config.getSpeedMultiplier(speedStat)
	local effTop = Sonic.TopSpeed * mult
	local grounded = hum.FloorMaterial ~= Enum.Material.Air
	local now = os.clock()

	-- Spindash LAUNCH window: drive forward regardless of input.
	if launching then
		if now < launchUntil then
			hum:Move(launchDir, false)
			currentSpeed = moveToward(currentSpeed, effTop, Sonic.Friction * dt * 0.5)
			hum.WalkSpeed = currentSpeed
			ClientState.runSpeed = currentSpeed
			ClientState.topSpeed = effTop
			return
		else
			launching = false
		end
	end

	local inputMag = inputMagnitude(hum)
	local hasInput = inputMag > 0.05

	if charging then
		-- Crouch & rev.
		chargeLevel = math.min(Config.SpindashMaxCharge, chargeLevel + (Config.SpindashMaxCharge / Config.SpindashChargeTime) * dt)
		currentSpeed = moveToward(currentSpeed, 0, Sonic.Deceleration * dt)
		ClientState.charging = true
		ClientState.chargeLevel = chargeLevel
	else
		-- Skid = pressing against your current motion at speed.
		local skidding = false
		if hasInput and currentSpeed > Sonic.TopSpeed * 0.4 then
			local vel = hrp.AssemblyLinearVelocity
			local vdir = Vector3.new(vel.X, 0, vel.Z)
			local md = hum.MoveDirection
			if vdir.Magnitude > 2 and md.Magnitude > 0.1 and vdir.Unit:Dot(md) < -0.25 then
				skidding = true
			end
		end

		if rolling and grounded then
			local rate = skidding and Sonic.RollDeceleration or Sonic.RollFriction
			currentSpeed = moveToward(currentSpeed, 0, rate * dt)
		elseif skidding then
			currentSpeed = moveToward(currentSpeed, 0, Sonic.Deceleration * dt)
		elseif hasInput then
			local accel = grounded and Sonic.Acceleration or Sonic.AirAcceleration
			-- accelerate up to top; preserve any overspeed (spindash).
			currentSpeed = moveToward(currentSpeed, math.max(effTop, currentSpeed), accel * dt)
		elseif grounded then
			currentSpeed = moveToward(currentSpeed, 0, Sonic.Friction * dt)
		end
	end

	currentSpeed = math.clamp(currentSpeed, 0, Sonic.GlobalSpeedCap * mult)
	hum.WalkSpeed = currentSpeed
	ClientState.runSpeed = currentSpeed
	ClientState.topSpeed = effTop
end)
