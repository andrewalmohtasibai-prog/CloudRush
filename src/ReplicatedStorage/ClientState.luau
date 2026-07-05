--!strict
--[[
	ClientState
	═══════════
	A tiny shared table for the client's LocalScripts. Because a ModuleScript is
	cached per-VM, both MovementController and CloudFX get the SAME table — so the
	movement script can publish the live run speed and the FX script can read it,
	with zero networking.
]]

local ClientState = {
	runSpeed = 0,   -- current momentum speed (studs/s)
	topSpeed = 0,   -- current max, from the Speed stat
	boosting = false,
}

return ClientState
