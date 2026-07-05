--!strict
--[[
	SonicPhysics
	════════════
	Authentic classic-Sonic (Genesis) movement constants, adapted from the
	Sonic Retro "Sonic Physics Guide" (https://info.sonicretro.org/Sonic_Physics_Guide).

	The guide's values are in "Sonic pixels per frame" at 60 FPS (with an 8-bit
	subpixel fraction, e.g. 0.046875 = 12/256). We convert them to studs/second and
	studs/second² so the controller is frame-rate independent.

	Conversion:
	  • SCALE      = studs per Sonic pixel (tunes the overall feel/scale)
	  • speed  (px/frame)  → studs/s   =  v × 60 × SCALE
	  • accel  (px/frame²) → studs/s²  =  a × 60 × 60 × SCALE

	Raw constants (Sonic 1/2/3):
	  acceleration 0.046875 · deceleration/skid 0.5 · friction 0.046875 · top 6
	  air acceleration 0.09375 · gravity 0.21875 · jump 6.5 · jump-release cap 4
	  roll friction 0.0234375 · roll deceleration 0.125 · global cap 16
	  spindash launch = 8 + floor(charge)/2   (charge 0..8)

	NOTE: 360° slope physics from the guide are intentionally NOT applied yet — our
	world is a flat following disc. The constants are here and the controller is
	written slope-ready, so when we add ramps/loops we plug slope factor in.
]]

local FPS = 60
local SCALE = 0.16 -- studs per Sonic pixel (tune this to scale the whole feel)

-- Raw guide values (Sonic units, per frame)
local RAW = {
	acceleration     = 0.046875,
	deceleration     = 0.5,      -- "skid" when pressing opposite your motion
	friction         = 0.046875, -- applied when no input on the ground
	top              = 6,        -- base running top speed
	airAcceleration  = 0.09375,  -- 2× ground acceleration
	gravity          = 0.21875,
	jump             = 6.5,      -- Sonic's jump velocity
	jumpReleaseCap   = 4,        -- variable jump height cap
	rollFriction     = 0.0234375,
	rollDeceleration = 0.125,
	globalSpeedCap   = 16,
	unrollSpeed      = 0.5,      -- below this while rolling → stand up
	minRollSpeed     = 1.0,      -- need at least this to start a roll
	slopeFactor      = 0.125,    -- (dormant until we have slopes)
}

local function spd(v: number): number  return v * FPS * SCALE end
local function acc(a: number): number  return a * FPS * FPS * SCALE end

local P = {
	Scale            = SCALE,
	Raw              = RAW,

	-- studs/second and studs/second²
	TopSpeed         = spd(RAW.top),               -- ~57.6
	Acceleration     = acc(RAW.acceleration),      -- ~27.0
	Friction         = acc(RAW.friction),          -- ~27.0
	Deceleration     = acc(RAW.deceleration),      -- ~288 (skid brake)
	AirAcceleration  = acc(RAW.airAcceleration),   -- ~54.0
	Gravity              = acc(RAW.gravity),
	JumpVelocity         = spd(RAW.jump),              -- ~62.4  (Humanoid.JumpPower)
	JumpReleaseVelocity  = spd(RAW.jumpReleaseCap),    -- ~38.4  (variable jump-height cap)
	RollFriction     = acc(RAW.rollFriction),
	RollDeceleration = acc(RAW.rollDeceleration),
	GlobalSpeedCap   = spd(RAW.globalSpeedCap),    -- ~153.6
	UnrollSpeed      = spd(RAW.unrollSpeed),
	MinRollSpeed     = spd(RAW.minRollSpeed),
	SlopeFactor      = acc(RAW.slopeFactor),
}

-- Spindash launch speed (studs/s) for a charge level 0..8.
-- Sonic: launch = 8 + floor(charge)/2  (pixels/frame).
function P.spindashSpeed(charge: number): number
	local c = math.clamp(charge, 0, RAW.globalSpeedCap)
	return spd(8 + math.floor(c) / 2)
end

return P
