--!strict
--[[
	WorldBuilder
	════════════
	Builds the shared CLOUD RUSH world once, on the server (so everyone sees the
	same dreamy sky). Returns handles the server + clients use.

	Perf notes baked in:
	  • Floor tiles have CastShadow = false (2,300 shadow casters would wreck FPS).
	  • Decorative clouds are simple SmoothPlastic balls (cheap draw calls).
	  • Sky depth comes from volumetric Terrain.Clouds + Atmosphere, not geometry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("CloudConfig"))

local WorldBuilder = {}

export type World = {
	root: Folder,
	floor: Folder,
	rings: Folder,
	gates: Folder,
	orb: Part,
}

local function newFolder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- ── Cloud floor: a flat grid of reactive tiles ──────────────
local function buildFloor(parent: Instance): Folder
	local floor = newFolder("Floor", parent)
	local tileY = Config.FloorTopY - Config.TileThickness * 0.5

	for i = 0, Config.FloorTiles - 1 do
		for j = 0, Config.FloorTiles - 1 do
			local x, z = Config.cellCenter(i, j)
			local tile = Instance.new("Part")
			tile.Name = "Tile"
			tile.Anchored = true
			tile.CanCollide = true
			tile.CastShadow = false
			tile.Size = Vector3.new(Config.TileSize, Config.TileThickness, Config.TileSize)
			tile.Position = Vector3.new(x, tileY, z)
			tile.Material = Enum.Material.SmoothPlastic
			tile.Color = Config.BaseTileColor
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.BottomSurface = Enum.SurfaceType.Smooth
			tile:SetAttribute("GX", i)
			tile:SetAttribute("GZ", j)
			tile.Parent = floor
		end
	end
	return floor
end

-- ── Decorative "sea of clouds" puffs around and below ───────
local function buildCloudSea(parent: Instance)
	local clouds = newFolder("CloudSea", parent)
	local half = Config.floorHalfExtent()

	for _ = 1, Config.CloudPuffCount do
		local angle = math.random() * math.pi * 2
		local dist = half + math.random(20, 260)
		local cx = math.cos(angle) * dist
		local cz = math.sin(angle) * dist
		local cy = math.random(-40, 6)

		-- Each "puff" is a little cluster of overlapping soft balls.
		local cluster = Instance.new("Model")
		cluster.Name = "Puff"
		for _ = 1, math.random(3, 6) do
			local b = Instance.new("Part")
			b.Shape = Enum.PartType.Ball
			b.Anchored = true
			b.CanCollide = false
			b.CastShadow = false
			b.Material = Enum.Material.SmoothPlastic
			b.Color = Color3.fromRGB(252, 253, 255)
			b.Transparency = 0.12
			local s = math.random(22, 46)
			b.Size = Vector3.new(s, s * 0.7, s)
			b.Position = Vector3.new(
				cx + math.random(-18, 18),
				cy + math.random(-6, 6),
				cz + math.random(-18, 18)
			)
			b.Parent = cluster
		end
		cluster.Parent = clouds
	end
end

-- ── The big floating orb (the moon-sphere from the reference) ─
local function buildOrb(parent: Instance): Part
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Size = Vector3.new(Config.OrbSize, Config.OrbSize, Config.OrbSize)
	orb.Position = Vector3.new(0, Config.OrbHeight, -Config.floorHalfExtent() * 0.5)
	orb.Material = Enum.Material.SmoothPlastic
	orb.Color = Color3.fromRGB(250, 249, 245)
	orb.Parent = parent
	return orb
end

-- ── A single ring collectible (spinning gold coin) ──────────
local function makeRing(position: Vector3): Part
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 216, 74)
	ring.Size = Vector3.new(0.35, 4, 4)
	-- Cylinder axis is along X, so the disc stands upright facing ±X.
	-- CloudFX spins it around Y → the classic "Sonic ring" flash.
	ring.CFrame = CFrame.new(position)
	ring:SetAttribute("Home", true)
	return ring
end

local function buildRings(parent: Instance): Folder
	local rings = newFolder("Rings", parent)
	local half = Config.floorHalfExtent() - Config.TileSize
	for _ = 1, Config.RingCount do
		local x = math.random(-half, half)
		local z = math.random(-half, half)
		local pos = Vector3.new(x, Config.FloorTopY + Config.RingFloatHeight, z)
		makeRing(pos).Parent = rings
	end
	return rings
end

-- ── Speed-gate arches (milestone markers, "reach X to open") ─
local function buildGates(parent: Instance): Folder
	local gates = newFolder("Gates", parent)

	for index, gate in Config.SpeedGates do
		local dist = 60 + (index - 1) * 90
		local model = Instance.new("Model")
		model.Name = "Gate_" .. gate.label
		model:SetAttribute("RequiredSpeed", gate.speed)
		model:SetAttribute("Opened", false)

		local function pillar(offsetX: number): Part
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(120, 180, 255)
			p.Size = Vector3.new(2, 26, 2)
			p.Position = Vector3.new(offsetX, 13, dist)
			p.Parent = model
			return p
		end
		pillar(-11)
		pillar(11)

		local top = Instance.new("Part")
		top.Anchored = true
		top.CanCollide = false
		top.CastShadow = false
		top.Material = Enum.Material.Neon
		top.Color = Color3.fromRGB(120, 180, 255)
		top.Size = Vector3.new(24, 2, 2)
		top.Position = Vector3.new(0, 26, dist)
		top.Parent = model

		-- translucent "locked" pane (cosmetic barrier that vanishes on open)
		local pane = Instance.new("Part")
		pane.Name = "Pane"
		pane.Anchored = true
		pane.CanCollide = false
		pane.CastShadow = false
		pane.Material = Enum.Material.ForceField
		pane.Color = Color3.fromRGB(150, 200, 255)
		pane.Transparency = 0.4
		pane.Size = Vector3.new(22, 24, 0.4)
		pane.Position = Vector3.new(0, 13, dist)
		pane.Parent = model

		-- floating label
		local billboardPart = top
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(10, 2.5)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Parent = billboardPart
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.TextScaled = true
		label.Text = string.format("%s\nSPEED %d", gate.label, gate.speed)
		label.Parent = bb

		model.Parent = gates
	end
	return gates
end

function WorldBuilder.build(): World
	local root = newFolder("CloudWorld", Workspace)

	local floor = buildFloor(root)
	buildCloudSea(root)
	local orb = buildOrb(root)
	local rings = buildRings(root)
	local gates = buildGates(root)

	-- Volumetric sky clouds (high-end depth, ~free perf-wise).
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain and not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.7
		clouds.Density = 0.55
		clouds.Color = Color3.fromRGB(255, 255, 255)
		clouds.Parent = terrain
	end

	return {
		root = root,
		floor = floor,
		rings = rings,
		gates = gates,
		orb = orb,
	}
end

return WorldBuilder
