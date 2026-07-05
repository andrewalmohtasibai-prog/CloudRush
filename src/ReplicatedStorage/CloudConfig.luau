--!strict
--[[
	CloudConfig
	═══════════
	Every tunable number for CLOUD RUSH.

	ARCHITECTURE (v2 — endless, no falling):
	  • Each player stands on a LARGE ground disc that FOLLOWS them every frame,
	    so the ground is always underfoot → you can never run off the edge, and it
	    feels infinite.
	  • A field of decorative cloud puffs sits in world space and WRAPS around the
	    player (a "treadmill") beyond the fog line, so you feel like you're moving
	    through an endless sky without ever seeing a hard edge.
	  • The floor "reacts" via a world-space COLOR-SPLAT TRAIL dropped at your feet
	    (hue cycling as you move) — this both looks better than recolouring tiles
	    and works with a moving floor.
	  • Keyboard-game loop: rings + running → +1 Speed (permanent) → higher top speed.
]]

local Config = {}

-- ════════════════════════════════════════════════════════════
--  MOVEMENT (Sonic-style momentum)
-- ════════════════════════════════════════════════════════════
Config.SpeedPerPound     = 1

Config.BaseTopSpeed      = 24
Config.TopSpeedPerSpeed  = 0.14
Config.MaxTopSpeed       = 320
Config.Acceleration      = 60     -- studs/sec² ramp toward top speed while holding input
Config.Friction          = 95     -- studs/sec² decel when input released
Config.JumpPower         = 55

-- Boost / spin-dash
Config.BoostSpeed        = 130
Config.BoostDuration     = 0.55
Config.BoostCooldown     = 1.1
Config.BaseFov           = 68
Config.SpeedFovMax       = 20     -- extra FOV added as you approach MaxTopSpeed
Config.BoostFovKick      = 16

-- ════════════════════════════════════════════════════════════
--  RINGS / SPEED GAIN (keyboard-game loop)
-- ════════════════════════════════════════════════════════════
Config.SpeedPerRing      = 1
Config.CoinsPerRing      = 1
Config.StudsPerSpeed     = 45     -- running this far also grants +1 Speed
Config.RingsPerPlayer    = 22     -- rings in each player's wrapping field
Config.RingFieldHalf     = 150    -- half-width of the ring field (studs) around the player
Config.RingFloatHeight   = 3.5

-- ════════════════════════════════════════════════════════════
--  GROUND (the following disc — "you can never fall")
-- ════════════════════════════════════════════════════════════
Config.GroundY           = 0
Config.GroundRadius      = 600    -- must be bigger than the fog view distance
Config.GroundThickness   = 4
Config.GroundColor       = Color3.fromRGB(240, 245, 252)  -- soft cool cloud white (not pure white → keeps depth)
Config.GroundFollowSnap  = 8      -- snap ground centre to this grid so it doesn't jitter

-- ════════════════════════════════════════════════════════════
--  CLOUD SEA (wrapping decorative puffs → sense of endless motion)
-- ════════════════════════════════════════════════════════════
Config.PuffClusters      = 64
Config.FieldHalf         = 420    -- puffs live within ±this of the player; they wrap
                                  -- when farther, which is BEYOND the fog so pops are hidden
Config.PuffMinY          = -55    -- some clouds sit below to read as "a sea below you"
Config.PuffMaxY          = 30
Config.PuffBallMin       = 20
Config.PuffBallMax       = 52
Config.PuffColorLow      = Color3.fromRGB(226, 235, 248)  -- shaded/base cloud
Config.PuffColorHigh     = Color3.fromRGB(255, 255, 255)  -- sunlit top

-- ════════════════════════════════════════════════════════════
--  REACTIVE COLOR TRAIL (the "floor changes colour as you move")
-- ════════════════════════════════════════════════════════════
Config.SplatSpacing      = 6      -- drop a colour splat every N studs travelled
Config.SplatLife         = 1.4    -- seconds a splat takes to fade out
Config.SplatBaseSize     = 10
Config.SplatSpeedSize    = 10     -- extra size at full speed
Config.HuePerStud        = 0.0016 -- how fast the colour cycles as you run
Config.SplatSaturation   = 0.55
Config.SplatValue        = 1.0
Config.MaxSplats         = 60     -- pool cap so the trail can't spam parts

-- ════════════════════════════════════════════════════════════
--  SKY ORB (client-side; follows the player so it's never left behind/cut off)
-- ════════════════════════════════════════════════════════════
Config.OrbSize           = 90
Config.OrbOffset         = Vector3.new(0, 150, -340)  -- relative to the player, in world axes
Config.OrbColor          = Color3.fromRGB(248, 246, 240)
Config.OrbBobAmplitude   = 6
Config.OrbBobSpeed       = 0.35

-- ════════════════════════════════════════════════════════════
--  SPEED MILESTONES (HUD celebration; was physical gates)
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
Config.SpawnHeight       = 5      -- studs above the ground disc
Config.SpawnFacing       = Vector3.new(0, 0, 1)  -- character looks +Z on spawn

-- ════════════════════════════════════════════════════════════
--  SOUNDS (paste your own asset ids; 0 = silent, still works)
-- ════════════════════════════════════════════════════════════
Config.Sounds = {
	Ring  = "rbxassetid://0",
	Boost = "rbxassetid://0",
	Milestone = "rbxassetid://0",
	Music = "rbxassetid://0",
}

-- ════════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════════
function Config.getTopSpeed(speed: number): number
	return math.min(Config.BaseTopSpeed + speed * Config.TopSpeedPerSpeed, Config.MaxTopSpeed)
end

-- Wrap a world coordinate into the range [-half, half] relative to a centre,
-- used to keep decorative items within a window around the player.
function Config.wrapAround(value: number, center: number, half: number): number
	local size = half * 2
	local d = value - center
	d = ((d + half) % size + size) % size - half
	return center + d
end

return Config
