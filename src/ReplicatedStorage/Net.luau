--!strict
--[[
	Net
	═══
	RemoteEvents for CLOUD RUSH. Server creates, client waits.

	  • RingCollected : server → client  { position, speed, rings }   (VFX + HUD)
	  • GateOpened    : server → client  { label, position }          (VFX)
	  • Boosted       : client → server  (optional analytics/validation hook)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "CloudRushRemotes"
local EVENT_NAMES = { "RingCollected", "GateOpened", "Boosted" }

local folder: Folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENT_NAMES do
		if not folder:FindFirstChild(name) then
			local re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local Net: { [string]: RemoteEvent } = {}
for _, name in EVENT_NAMES do
	Net[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Net
