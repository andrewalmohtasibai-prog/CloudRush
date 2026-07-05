--!strict
--[[
	WorldBuilder
	════════════
	Factories for the CLOUD RUSH world. The server owns instances and drives their
	movement (following ground, wrapping clouds), so this module just builds parts.

	Perf notes:
	  • Ground is ONE big disc per player (1 draw group), not thousands of tiles.
	  • Puffs / rings have CastShadow = false and CanCollide = false.
	  • Sky depth comes from volumetric Terrain.Clouds + Atmosphere + fog, not geometry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))

local WorldBuilder = {}

-- ── Shared, one-time world setup ────────────────────────────
function WorldBuilder.build(): Folder
	local root = Workspace:FindFirstChild("CloudWorld")
	if not root then
		root = Instance.new("Folder")
		root.Name = "CloudWorld"
		root.Parent = Workspace
	end

	-- Volumetric sky clouds (cheap depth). Lower Cover so blue sky still shows.
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain and not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.5
		clouds.Color = Color3.fromRGB(255, 255, 255)
		clouds.Parent = terrain
	end

	return root :: Folder
end

-- ── The following ground disc (you can never fall off) ──────
function WorldBuilder.makeGround(): Part
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Shape = Enum.PartType.Cylinder
	ground.Anchored = true
	ground.CanCollide = true
	ground.CastShadow = false
	-- Cylinder axis is along X; rotate so it lies flat (axis → Y) as a disc.
	ground.Size = Vector3.new(Config.GroundThickness, Config.GroundRadius * 2, Config.GroundRadius * 2)
	ground.Material = Enum.Material.SmoothPlastic
	ground.Color = Config.GroundColor
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.CFrame = CFrame.new(0, Config.GroundY - Config.GroundThickness * 0.5, 0)
		* CFrame.Angles(0, 0, math.rad(90))
	return ground
end

-- Position the ground disc's top at GroundY under a given XZ.
function WorldBuilder.moveGround(ground: Part, x: number, z: number)
	ground.CFrame = CFrame.new(x, Config.GroundY - Config.GroundThickness * 0.5, z)
		* CFrame.Angles(0, 0, math.rad(90))
end

-- ── A soft cloud puff (cluster of shaded balls) ─────────────
function WorldBuilder.makePuffCluster(): Model
	local cluster = Instance.new("Model")
	cluster.Name = "Puff"

	local ballCount = math.random(4, 7)
	local anchor: BasePart? = nil
	for i = 1, ballCount do
		local b = Instance.new("Part")
		b.Shape = Enum.PartType.Ball
		b.Anchored = true
		b.CanCollide = false
		b.CastShadow = false
		b.Material = Enum.Material.SmoothPlastic
		-- Lower balls a touch darker/bluer, top balls sunlit → fake volume/shading.
		local up = math.random()
		b.Color = Config.PuffColorLow:Lerp(Config.PuffColorHigh, up)
		b.Transparency = 0.06
		local s = math.random(Config.PuffBallMin, Config.PuffBallMax)
		b.Size = Vector3.new(s, s * 0.66, s)
		b.Position = Vector3.new(
			math.random(-22, 22),
			up * 10 + math.random(-3, 3),
			math.random(-22, 22)
		)
		b.Parent = cluster
		if i == 1 then anchor = b end
	end
	if anchor then cluster.PrimaryPart = anchor end
	return cluster
end

-- ── A ring collectible (gold neon coin; CloudFX spins it) ───
function WorldBuilder.makeRing(position: Vector3): Part
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 210, 64)
	ring.Size = Vector3.new(0.5, 6, 6)     -- thin disc, ~6 studs across
	ring.CFrame = CFrame.new(position)      -- axis along X → stands upright, spun by client
	ring:SetAttribute("Available", true)    -- distance-based pickup checks this
	return ring
end

return WorldBuilder
