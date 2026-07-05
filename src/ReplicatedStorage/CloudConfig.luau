--!strict
--[[
	CloudConfig
	═══════════
	Every tunable number for CLOUD RUSH.

	ARCHITECTURE (v2 — endless, no falling):
	  • A LARGE ground disc FOLLOWS each player → you can never run off the edge.
	  • A field of cloud puffs WRAPS around the player beyond the fog → endless feel.
	  • The floor "reacts" via a world-space COLOUR-SPLAT TRAIL at your feet.
	  • Keyboard-game loop: rings + running → +1 Speed → higher top speed.

	MOVEMENT (v3 — authentic Sonic physics):
	  • Raw Genesis constants live in SonicPhysics.luau (acceleration, friction,
	    top speed, spindash, etc., converted from Sonic-pixels to studs).
	  • The numbers below scale that base by your permanent Speed stat and tune the
	    spindash charge.
]]

local Config = {}

-- ════════════════════════════════════════════════════════════
--  SONIC PROGRESSION  (Speed stat → faster top speed)
-- ════════════════════════════════════════════════════════════
-- Effective top speed = SonicPhysics.TopSpeed × (1 + Speed × SpeedMultPerStat),
-- capped at × SpeedMultMax. Keeps the Sonic feel while the grind makes you faster.
Config.SpeedMultPerStat  = 0.0025
Config.SpeedMultMax      = 7

-- Spindash (hold to charge, release to launch — the satisfying "charge & go")
Config.SpindashChargeTime = 0.9   -- seconds of holding to reach full charge
Config.SpindashMaxCharge  = 8     -- Sonic's max charge level (launch = 8 + charge/2 px/f)
Config.SpindashHoldSlow   = 0.15  -- while charging you're slowed to this fraction of speed

-- Jump (Humanoid handles Y; the controller drives XZ)
Config.JumpPower         = 55

-- Reference speed cap used only for FX scaling (FOV / splat size).
Config.MaxTopSpeed       = 380

-- Camera feel
Config.BaseFov           = 68
Config.SpeedFovMax       = 22     -- extra FOV as you approach the speed cap
Config.BoostFovKick      = 16     -- extra FOV on a spindash launch

-- ════════════════════════════════════════════════════════════
--  RINGS / SPEED GAIN (keyboard-game loop)
-- ════════════════════════════════════════════════════════════
Config.SpeedPerRing      = 1
Config.CoinsPerRing      = 1
Config.StudsPerSpeed     = 45     -- running this far also grants +1 Speed
Config.RingsPerPlayer    = 22
Config.RingFieldHalf     = 150
Config.RingFloatHeight   = 3.5

-- ════════════════════════════════════════════════════════════
--  GROUND (the following disc — "you can never fall")
-- ════════════════════════════════════════════════════════════
Config.GroundY           = 0
Config.GroundRadius      = 600
Config.GroundThickness   = 4
Config.GroundColor       = Color3.fromRGB(240, 245, 252)
Config.GroundFollowSnap  = 8

-- ════════════════════════════════════════════════════════════
--  CLOUD SEA (wrapping decorative puffs)
-- ════════════════════════════════════════════════════════════
Config.PuffClusters      = 64
Config.FieldHalf         = 420
Config.PuffMinY          = -55
Config.PuffMaxY          = 30
Config.PuffBallMin       = 20
Config.PuffBallMax       = 52
Config.PuffColorLow      = Color3.fromRGB(226, 235, 248)
Config.PuffColorHigh     = Color3.fromRGB(255, 255, 255)

-- ════════════════════════════════════════════════════════════
--  REACTIVE COLOUR TRAIL
-- ════════════════════════════════════════════════════════════
Config.SplatSpacing      = 6
Config.SplatLife         = 1.4
Config.SplatBaseSize     = 10
Config.SplatSpeedSize    = 10
Config.HuePerStud        = 0.0016
Config.SplatSaturation   = 0.55
Config.SplatValue        = 1.0
Config.MaxSplats         = 60

-- ════════════════════════════════════════════════════════════
--  SKY ORB (client-side; follows the player)
-- ════════════════════════════════════════════════════════════
Config.OrbSize           = 90
Config.OrbOffset         = Vector3.new(0, 150, -340)
Config.OrbColor          = Color3.fromRGB(248, 246, 240)
Config.OrbBobAmplitude   = 6
Config.OrbBobSpeed       = 0.35

-- ════════════════════════════════════════════════════════════
--  SPEED MILESTONES (HUD celebration)
-- ════════════════════════════════════════════════════════════
Config.SpeedMilestones = {
	{ speed = 50,   label = "SKY RUNNER" },
	{ speed = 200,  label = "STORM CHASER" },
	{ speed = 600,  label = "AURORA" },
	{ speed = 1500, label = "COSMIC" },
}

-- ════════════════════════════════════════════════════════════
--  SPAWN
-- ════════════════════════════════════════════════════════════
Config.SpawnHeight       = 5
Config.SpawnFacing       = Vector3.new(0, 0, 1)

-- ════════════════════════════════════════════════════════════
--  SOUNDS (paste your own asset ids; 0 = silent, still works)
-- ════════════════════════════════════════════════════════════
Config.Sounds = {
	Ring      = "rbxassetid://0",  -- ring "ching"
	Charge    = "rbxassetid://0",  -- spindash rev (pitch ladders up while charging → ASMR)
	Launch    = "rbxassetid://0",  -- spindash release "whoosh"
	Milestone = "rbxassetid://0",  -- milestone fanfare
	Music     = "rbxassetid://0",  -- ambient loop
}

-- ════════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════════
-- Multiplier applied to the base Sonic top speed from your Speed stat.
function Config.getSpeedMultiplier(speed: number): number
	return math.min(1 + speed * Config.SpeedMultPerStat, Config.SpeedMultMax)
end

-- Keep a decorative item within ±half of the player (used for initial placement).
function Config.wrapAround(value: number, center: number, half: number): number
	local size = half * 2
	local d = value - center
	d = ((d + half) % size + size) % size - half
	return center + d
end

return Config
