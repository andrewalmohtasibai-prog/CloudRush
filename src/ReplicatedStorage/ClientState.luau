--!strict
--[[
	ClientState
	═══════════
	Shared table between the client LocalScripts (same VM → same table).
	MovementController publishes; CloudFX reads. Zero networking.
]]

local ClientState = {
	runSpeed = 0,      -- current ground speed magnitude (studs/s)
	topSpeed = 0,      -- current effective top speed
	boosting = false,  -- true briefly on a spindash launch (drives FOV kick + launch SFX)
	charging = false,  -- true while charging a spindash (drives the rev pitch-ladder SFX)
	chargeLevel = 0,   -- 0..SpindashMaxCharge
	rolling = false,   -- true while rolling
}

return ClientState
