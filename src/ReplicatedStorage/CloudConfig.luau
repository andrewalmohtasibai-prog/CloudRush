--!strict
--[[
	CloudConfig
	═══════════
	Every tunable number for CLOUD RUSH.

	WORLD (v2 — endless, no falling):
	  • A large ground disc FOLLOWS each player → you can never run off the edge.
	  • Cloud puffs WRAP around the player beyond the fog → endless feel.
	  • The floor "reacts" via a world-space COLOUR-SPLAT trail at your feet.

	MOVEMENT (v4 — Humanoid-native Sonic feel):
	  • Sonic constants live in SonicPhysics.luau (accel/friction/skid/top/spindash).
	  • We drive Humanoid.WalkSpeed with that curve — no fighting the engine.
	  • The Speed STAT grows forever (progression/flex), but actual WALKSPEED is
	    capped to a Humanoid-stable range (MaxWalkSpeed) so movement stays smooth.
	    Beyond the cap, "faster" is sold through FOV / speed-lines / trail, not raw
	    WalkSpeed (which gets unstable in the hundreds).
]]

local Config = {}

-- ════════════════════════════════════════════════════════════
--  SPEED / PROGRESSION
-- ════════════════════════════════════════════════════════════
-- Effective top speed = min(SonicPhysics.TopSpeed × mult, MaxWalkSpeed).
Config.SpeedMultPerStat  = 0.0025
Config.SpeedMultMax      = 4
Config.MaxWalkSpeed      = 120    -- Humanoid stays smooth up to ~this; keep movement here
Config.AccelerationScale = 2.0    -- Roblox-runner tuning of Sonic's base acceleration

-- ════════════════════════════════════════════════════════════
--  SPINDASH (hold to charge — rev pitch ladders up — release to launch)
-- ════════════════════════════════════════════════════════════
Config.SpindashChargeTime = 0.9   -- seconds to full charge
Config.SpindashMaxCharge  = 8     -- Sonic's max (launch = 8 + charge/2 px/f)
Config.SpindashLaunchTime = 0.45  -- how long the forward launch is driven

-- ════════════════════════════════════════════════════════════
--  CAMERA FEEL
-- ════════════════════════════════════════════════════════════
Config.BaseFov           = 68
Config.SpeedFovMax       = 22     -- extra FOV as you approach top speed
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
Config.RingPickupRadius  = 6      -- distance-based pickup (never misses at speed)
Config.RingRespawn       = 2.5

-- ════════════════════════════════════════════════════════════
--  GROUND (the following disc — "you can never fall")
-- ════════════════════════════════════════════════════════════
Config.GroundY           = 0
Config.GroundRadius      = 600
Config.GroundThickness   = 4
Config.GroundColor       = Color3.fromRGB(240, 245, 252)
Config.GroundFollowSnap  = 8      -- ground/decor recentre step (studs)

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
Config.SplatSpacing      = 6      -- min studs travelled between splats
Config.SplatMinInterval  = 0.05   -- min seconds between splats (caps ~20/sec)
Config.SplatLife         = 1.4
Config.SplatBaseSize     = 10
Config.SplatSpeedSize    = 10
Config.HuePerStud        = 0.0016
Config.SplatSaturation   = 0.55
Config.SplatValue        = 1.0
Config.MaxSplats         = 45

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
	Ring      = "rbxassetid://0",
	Charge    = "rbxassetid://0",  -- spindash rev (pitch ladders up → ASMR)
	Launch    = "rbxassetid://0",  -- spindash release whoosh
	Milestone = "rbxassetid://0",
	Music     = "rbxassetid://0",
}

-- ════════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════════
function Config.getSpeedMultiplier(speed: number): number
	return math.min(1 + speed * Config.SpeedMultPerStat, Config.SpeedMultMax)
end

return Config
