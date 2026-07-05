--!strict
--[[
	MovementController
	══════════════════
	Sonic-style momentum on top of the standard Humanoid:
	  • Hold a direction → accelerate toward your top speed; release → friction.
	  • Top speed rises with your permanent Speed stat.
	  • BOOST (Shift / R2 / on-screen button) = instant burst.
	Also frames the camera BEHIND the character on spawn so you face forward.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local ClientState = require(ReplicatedStorage:WaitForChild("ClientState"))

local player = Players.LocalPlayer

-- ControlModule for robust raw input (works even when WalkSpeed dips to 0).
local controls
task.spawn(function()
	pcall(function()
		local ps = player:WaitForChild("PlayerScripts")
		local PlayerModule = require(ps:WaitForChild("PlayerModule")) :: any
		controls = PlayerModule:GetControls()
	end)
end)

local currentSpeed = Config.BaseTopSpeed
local boostActive = false
local boostEnd = 0
local cooldownEnd = 0

-- ── Boost ───────────────────────────────────────────────────
local function onBoost(_, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local now = os.clock()
	if now < cooldownEnd then return Enum.ContextActionResult.Pass end
	boostActive = true
	boostEnd = now + Config.BoostDuration
	cooldownEnd = now + Config.BoostCooldown
	ClientState.boosting = true
	Net.Boosted:FireServer()
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("CloudBoost", onBoost, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("CloudBoost", "BOOST")
ContextActionService:SetPosition("CloudBoost", UDim2.new(1, -120, 0.55, 0))

-- ── Camera framing on spawn ─────────────────────────────────
local function frameCameraBehind()
	local camera = Workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not hrp then return end
	local behind = hrp.Position - Config.SpawnFacing.Unit * 16 + Vector3.new(0, 6, 0)
	camera.CFrame = CFrame.lookAt(behind, hrp.Position + Vector3.new(0, 2, 0))
end

player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	task.wait(0.25)
	frameCameraBehind()
end)

-- ── Helpers ─────────────────────────────────────────────────
local function moveToward(a: number, b: number, maxDelta: number): number
	if a < b then return math.min(a + maxDelta, b) else return math.max(a - maxDelta, b) end
end

local function inputMagnitude(hum: Humanoid): number
	if controls then
		local ok, vec = pcall(function() return controls:GetMoveVector() end)
		if ok and vec then return vec.Magnitude end
	end
	return hum.MoveDirection.Magnitude
end

-- ── Momentum loop ───────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local topSpeed = Config.getTopSpeed(player:GetAttribute("Speed") or 0)

	local now = os.clock()
	if boostActive and now > boostEnd then
		boostActive = false
		ClientState.boosting = false
	end

	local hasInput = inputMagnitude(hum) > 0.05
	local target
	if boostActive then
		target = topSpeed + Config.BoostSpeed
	elseif hasInput then
		target = topSpeed
	else
		target = 0
	end

	local rate = (hasInput or boostActive) and Config.Acceleration or Config.Friction
	if boostActive then rate = rate * 6 end
	currentSpeed = moveToward(currentSpeed, target, rate * dt)

	hum.WalkSpeed = currentSpeed
	ClientState.runSpeed = currentSpeed
	ClientState.topSpeed = topSpeed
end)
