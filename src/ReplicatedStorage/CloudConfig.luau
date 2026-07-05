--!strict
--[[
	CloudConfig
	═══════════
	Every tunable number for CLOUD RUSH. Change here → whole game re-balances.

	The fusion:
	  • Sonic feel   → momentum: accelerate to a high top speed, keep it, boost.
	  • Keyboard loop → collect rings / run → +1 Speed (permanent) → higher top speed forever.
	  • Cloud world  → a color-reactive sea of clouds you sprint across.
]]

local Config = {}

-- ════════════════════════════════════════════════════════════
--  MOVEMENT  (Sonic-style momentum)
-- ════════════════════════════════════════════════════════════
Config.BaseTopSpeed     = 26     -- top speed with 0 Speed stat
Config.TopSpeedPerSpeed = 0.14   -- each point of the Speed stat raises top speed
Config.MaxTopSpeed      = 320    -- hard cap so it stays controllable
Config.Acceleration     = 55     -- studs/sec² ramp toward top speed while holding a direction
Config.Friction         = 80     -- studs/sec² decel when you release input
Config.TurnResponse     = 9      -- how snappily the run direction follows input (higher = snappier)

Config.JumpPower        = 55

-- Boost / spin-dash
Config.BoostSpeed       = 130    -- extra speed added by a boost
Config.BoostDuration    = 0.55   -- seconds the boost lasts
Config.BoostCooldown    = 1.1    -- seconds between boosts
Config.BoostFovKick     = 22     -- FOV added during boost (whoosh feel)
Config.BaseFov          = 70

-- ════════════════════════════════════════════════════════════
--  RINGS  (the +1 Speed keyboard-loop currency)
-- ════════════════════════════════════════════════════════════
Config.SpeedPerRing     = 1      -- +1 Speed per ring (your rule, Sonic-flavored)
Config.CoinsPerRing     = 1
Config.StudsPerSpeed    = 45     -- running this many studs also grants +1 Speed (movement is rewarded)
Config.RingRespawn      = 5      -- seconds before a collected ring returns
Config.RingCount        = 140    -- rings scattered across the cloud field
Config.RingFloatHeight  = 3.2    -- how high rings hover above the clouds

-- ════════════════════════════════════════════════════════════
--  REACTIVE CLOUD FLOOR  (color changes as you move)
-- ════════════════════════════════════════════════════════════
Config.FloorTiles       = 48     -- tiles per side (48×48 = 2,304 tiles)
Config.TileSize         = 12      -- studs per tile
Config.TileThickness    = 1
Config.FloorTopY        = 0       -- top surface of the cloud floor
Config.BaseTileColor    = Color3.fromRGB(248, 250, 255)  -- soft cloud white
Config.BloomRadiusCells = 3       -- how many tiles around you light up
Config.ColorFadeTime    = 1.6     -- seconds a colored tile takes to fade back to white
Config.HuePerStud       = 0.0016  -- how fast the color cycles as you travel
Config.TileSaturation   = 0.55
Config.TileValue        = 1.0

-- ════════════════════════════════════════════════════════════
--  SPEED GATES  (keyboard-game "reach X to pass")
--  Ring pillars/arches that only open once your Speed stat is high enough.
-- ════════════════════════════════════════════════════════════
Config.SpeedGates = {
	{ speed = 50,   label = "SKY GATE"    },
	{ speed = 200,  label = "STORM GATE"  },
	{ speed = 600,  label = "AURORA GATE" },
	{ speed = 1500, label = "COSMIC GATE" },
}

-- ════════════════════════════════════════════════════════════
--  WORLD DECOR
-- ════════════════════════════════════════════════════════════
Config.OrbSize          = 46
Config.OrbHeight        = 70
Config.OrbBobAmplitude  = 4
Config.OrbBobSpeed      = 0.4
Config.CloudPuffCount   = 90     -- decorative floating cloud blobs

-- ════════════════════════════════════════════════════════════
--  SOUNDS  (paste your own asset ids; 0 = silent, still works)
-- ════════════════════════════════════════════════════════════
Config.Sounds = {
	Ring  = "rbxassetid://0",  -- classic ring "ching"
	Boost = "rbxassetid://0",  -- whoosh
	Gate  = "rbxassetid://0",  -- gate opens
}

-- ════════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════════

-- Top speed for a given accumulated Speed stat.
function Config.getTopSpeed(speed: number): number
	return math.min(Config.BaseTopSpeed + speed * Config.TopSpeedPerSpeed, Config.MaxTopSpeed)
end

-- Grid-cell → world XZ of that tile's centre.
function Config.cellCenter(i: number, j: number): (number, number)
	local half = Config.FloorTiles / 2
	local x = (i - half + 0.5) * Config.TileSize
	local z = (j - half + 0.5) * Config.TileSize
	return x, z
end

-- World XZ → grid cell.
function Config.worldToCell(x: number, z: number): (number, number)
	local half = Config.FloorTiles / 2
	local i = math.floor(x / Config.TileSize + half)
	local j = math.floor(z / Config.TileSize + half)
	return i, j
end

function Config.floorHalfExtent(): number
	return Config.FloorTiles * Config.TileSize * 0.5
end

return Config
