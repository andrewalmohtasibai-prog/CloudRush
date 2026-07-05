--!strict
--[[
	MovementController  (v3 — authentic Sonic physics)
	══════════════════════════════════════════════════
	A velocity-based controller adapting the Sonic Physics Guide:
	  • Ground: accelerate toward input, SKID when you press against your motion,
	    FRICTION when you let go — true momentum and inertia, not instant turns.
	  • Air: weaker air-acceleration, no friction (Humanoid handles gravity + jump).
	  • ROLL (Ctrl / on-screen): keep momentum, lose the ability to accelerate.
	  • SPINDASH (hold Shift / on-screen): crouch & charge (rev pitch ladders up),
	    release to launch — the satisfying "charge & go" that echoes the keyboard game.
	  • Your permanent Speed stat multiplies the base top speed.

	Implementation notes:
	  • We keep the Humanoid for ground collision + jump + gravity (Y), set WalkSpeed 0
	    and AutoRotate off, and drive XZ with a LinearVelocity constraint.
	  • Facing uses AlignOrientation so we don't stomp physics with CFrame writes.
	  • Slope (360°) physics is intentionally dormant until the world has ramps/loops.
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

-- ── ControlModule for robust raw input ─────────────────────
local controls
task.spawn(function()
	pcall(function()
		local ps = player:WaitForChild("PlayerScripts")
		local PlayerModule = require(ps:WaitForChild("PlayerModule")) :: any
		controls = PlayerModule:GetControls()
	end)
end)

-- ── Per-character rig ───────────────────────────────────────
local hum: Humanoid? = nil
local hrp: BasePart? = nil
local linVel: LinearVelocity? = nil
local align: AlignOrientation? = nil

local vel = Vector2.zero           -- ground velocity (X,Z) in studs/s
local faceDir = Config.SpawnFacing -- last facing (Vector3, flattened)
local rolling = false
local charging = false
local chargeLevel = 0

local function setup(character: Model)
	hum = character:WaitForChild("Humanoid") :: Humanoid
	hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	local h = hum :: Humanoid
	local root = hrp :: BasePart

	h.WalkSpeed = 0
	h.AutoRotate = false
	h.UseJumpPower = true
	h.JumpPower = Config.JumpPower

	local att = root:FindFirstChild("MoveAtt") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "MoveAtt"
		att.Parent = root
	end

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root
	linVel = lv

	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = false
	ao.MaxTorque = 1e6
	ao.Responsiveness = 40
	ao.Parent = root
	align = ao

	vel = Vector2.zero
	rolling = false
	charging = false
	chargeLevel = 0
	ClientState.rolling = false
	ClientState.charging = false
	ClientState.chargeLevel = 0

	-- Camera behind on spawn.
	task.wait(0.2)
	local cam = Workspace.CurrentCamera
	if cam and root and root.Parent then
		local behind = root.Position - Config.SpawnFacing.Unit * 16 + Vector3.new(0, 6, 0)
		cam.CFrame = CFrame.lookAt(behind, root.Position + Vector3.new(0, 2, 0))
	end
end

player.CharacterAdded:Connect(setup)
if player.Character then
	task.spawn(setup, player.Character)
end

-- ── Input: spindash + roll ──────────────────────────────────
local function onSpindash(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		charging = true
		chargeLevel = 0
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if charging then
			charging = false
			local grounded = hum and hum.FloorMaterial ~= Enum.Material.Air
			if grounded and chargeLevel > 0.15 then
				local mult = Config.getSpeedMultiplier(player:GetAttribute("Speed") or 0)
				local launch = Sonic.spindashSpeed(chargeLevel) * math.sqrt(mult)
				local dir = Vector2.new(faceDir.X, faceDir.Z)
				if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
				vel = dir.Unit * launch
				ClientState.boosting = true
				task.delay(0.4, function() ClientState.boosting = false end)
				Net.Boosted:FireServer()
			end
			chargeLevel = 0
			ClientState.charging = false
			ClientState.chargeLevel = 0
		end
	end
	return Enum.ContextActionResult.Sink
end

local function onRoll(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		local grounded = hum and hum.FloorMaterial ~= Enum.Material.Air
		if grounded and vel.Magnitude >= Sonic.MinRollSpeed then
			rolling = true
			ClientState.rolling = true
		end
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
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

-- ── Input direction (world XZ) ──────────────────────────────
local function getInputDir(): (Vector2, number)
	if not controls then return Vector2.zero, 0 end
	local ok, mv = pcall(function() return controls:GetMoveVector() end)
	if not ok or typeof(mv) ~= "Vector3" then return Vector2.zero, 0 end
	local mag = math.min(mv.Magnitude, 1)
	if mag < 0.05 then return Vector2.zero, 0 end
	local cam = Workspace.CurrentCamera
	if not cam then return Vector2.zero, 0 end
	local world = cam.CFrame:VectorToWorldSpace(mv)
	local flat = Vector2.new(world.X, world.Z)
	if flat.Magnitude < 1e-3 then return Vector2.zero, 0 end
	return flat.Unit, mag
end

-- ── Main physics loop ───────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
	local h = hum
	local root = hrp
	local lv = linVel
	local ao = align
	if not h or not root or not lv or not ao then return end

	local grounded = h.FloorMaterial ~= Enum.Material.Air
	local inputDir, inputMag = getInputDir()
	local speedStat = player:GetAttribute("Speed") or 0
	local effTop = Sonic.TopSpeed * Config.getSpeedMultiplier(speedStat)

	if charging then
		-- Crouch & rev: bleed to (near) still, ramp charge, publish for the SFX ladder.
		chargeLevel = math.min(Config.SpindashMaxCharge, chargeLevel + (Config.SpindashMaxCharge / Config.SpindashChargeTime) * dt)
		vel = vel * math.clamp(1 - dt * 8, Config.SpindashHoldSlow, 1)
		ClientState.charging = true
		ClientState.chargeLevel = chargeLevel
	elseif grounded and rolling then
		-- Rolling: no acceleration, low friction, extra brake if pressing back.
		local m = vel.Magnitude
		if inputMag > 0.05 and m > 0 and vel.Unit:Dot(inputDir) < 0 then
			m = math.max(0, m - Sonic.RollDeceleration * dt)
		end
		m = math.max(0, m - Sonic.RollFriction * dt)
		if m > 0 and vel.Magnitude > 0 then vel = vel.Unit * m end
		if m < Sonic.UnrollSpeed then rolling = false; ClientState.rolling = false end
	elseif grounded then
		if inputMag > 0.05 then
			local m = vel.Magnitude
			if m > 0 and vel.Unit:Dot(inputDir) < 0 then
				-- Skid: hard brake against your motion.
				m = math.max(0, m - Sonic.Deceleration * dt)
				vel = (m > 0) and vel.Unit * m or Vector2.zero
			end
			-- Accelerate only while below top speed (so spindash overspeed is kept).
			if vel.Magnitude < effTop then
				vel = vel + inputDir * Sonic.Acceleration * dt
				if vel.Magnitude > effTop then vel = vel.Unit * effTop end
			else
				-- Above top: steer without gaining speed.
				local sp = vel.Magnitude
				vel = vel:Lerp(inputDir * sp, math.clamp(dt * 3, 0, 1))
			end
		else
			-- Friction.
			local m = vel.Magnitude
			if m > 0 then vel = vel.Unit * math.max(0, m - Sonic.Friction * dt) end
		end
	else
		-- Airborne: weaker air control, no friction.
		if inputMag > 0.05 and vel.Magnitude < effTop then
			vel = vel + inputDir * Sonic.AirAcceleration * dt
			if vel.Magnitude > effTop then vel = vel.Unit * effTop end
		end
	end

	-- Facing: follow motion, or input when nearly still.
	if vel.Magnitude > 1 then
		faceDir = Vector3.new(vel.X, 0, vel.Y).Unit
	elseif inputMag > 0.05 then
		faceDir = Vector3.new(inputDir.X, 0, inputDir.Y).Unit
	end
	ao.CFrame = CFrame.lookAt(Vector3.zero, faceDir)

	-- Apply XZ velocity; keep the physics Y (gravity + Humanoid jump).
	lv.VectorVelocity = Vector3.new(vel.X, root.AssemblyLinearVelocity.Y, vel.Y)

	ClientState.runSpeed = vel.Magnitude
	ClientState.topSpeed = effTop
end)
