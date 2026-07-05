--!strict
--[[
	MovementController
	══════════════════
	Sonic-style momentum on top of the standard Humanoid:
	  • Hold a direction → currentSpeed ACCELERATES toward your top speed.
	  • Release → FRICTION bleeds it back down (you keep momentum for a beat).
	  • Top speed rises with your permanent Speed stat (keyboard-loop payoff).
	  • BOOST (Shift / R2 / on-screen button) = an instant burst + FOV whoosh.

	We drive Humanoid.WalkSpeed from the momentum scalar and read raw input from
	the ControlModule (robust even when WalkSpeed dips to 0).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local ClientState = require(ReplicatedStorage:WaitForChild("ClientState"))

local player = Players.LocalPlayer

-- Grab the ControlModule so we can read raw movement input reliably.
local controls
task.spawn(function()
	local ok = pcall(function()
		local playerScripts = player:WaitForChild("PlayerScripts")
		local PlayerModule = require(playerScripts:WaitForChild("PlayerModule")) :: any
		controls = PlayerModule:GetControls()
	end)
	if not ok then
		controls = nil
	end
end)

local currentSpeed = Config.BaseTopSpeed
local boostActive = false
local boostEnd = 0
local cooldownEnd = 0

-- ── Boost input (keyboard / gamepad / mobile button) ────────
local function onBoost(_, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local now = os.clock()
	if now < cooldownEnd then
		return Enum.ContextActionResult.Pass
	end
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

-- ── Helpers ─────────────────────────────────────────────────
local function moveToward(a: number, b: number, maxDelta: number): number
	if a < b then
		return math.min(a + maxDelta, b)
	else
		return math.max(a - maxDelta, b)
	end
end

local function inputMagnitude(hum: Humanoid): number
	if controls then
		local ok, vec = pcall(function()
			return controls:GetMoveVector()
		end)
		if ok and vec then
			return vec.Magnitude
		end
	end
	return hum.MoveDirection.Magnitude
end

-- ── Main momentum loop ──────────────────────────────────────
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
	if boostActive then
		rate = rate * 6 -- snap into the boost
	end
	currentSpeed = moveToward(currentSpeed, target, rate * dt)

	hum.WalkSpeed = currentSpeed
	ClientState.runSpeed = currentSpeed
	ClientState.topSpeed = topSpeed
end)
