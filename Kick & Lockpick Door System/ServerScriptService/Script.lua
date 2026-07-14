-- Author: sac_ie

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local KeyframeProvider = game:GetService("KeyframeSequenceProvider")
local PhysicsService = game:GetService("PhysicsService")
local ContentProvider = game:GetService("ContentProvider")

local Door = require(RS.Shared.Door)

local Remotes = RS:WaitForChild("Remotes").Doors
local Doors = game.Workspace:WaitForChild("Doors")

local COLLISION_GROUP_DOORS = "Doors"
local COLLISION_GROUP_PLAYERS = "Players"

local REMOTE_DOOR_STATE = Remotes.State
local REMOTE_ACTION = Remotes.Action
local REMOTE_REQUEST_STATE = Remotes.RequestState
local REMOTE_SYNC_STATE = Remotes.SyncState

local activeDoors = {} -- [id] = Door instance

-----------------------------
-- Preload animations
-----------------------------

local function preloadAnimations()
	local lengthCache = {}
	local toPreload = {}
	
	for _, actionData in pairs(Door.Actions) do
		local animation = actionData.Animation
		local animationId = actionData.AnimationId
		if not animation or not animationId then continue end
		
		table.insert(toPreload, animation)
		
		if lengthCache[animationId] == nil then
			local ok, result = pcall(function()
				local sequence = KeyframeProvider:GetKeyframeSequenceAsync(animationId)
				local keyframes = sequence:GetKeyframes()
				
				local length = 0
				for _, keyframe in ipairs(keyframes) do
					length = math.max(length, keyframe.Time)
				end
				
				sequence:Destroy()
				return length
			end)
			
			if not ok then
				warn(`Failed to measure animation {animationId}: {result}`)
			end
			
			lengthCache[animationId] = ok and result or 0
		end
		
		actionData.AnimationLength = lengthCache[animationId]
	end
	
	pcall(function()
		ContentProvider:PreloadAsync(toPreload)
	end)
end

preloadAnimations()

-----------------------------
-- Collision groups
-----------------------------

pcall(function()
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP_DOORS, COLLISION_GROUP_PLAYERS, true)
end)

local function setDoorCollisionGroup(model: Model)
	if model.PrimaryPart then
		model.PrimaryPart.CollisionGroup = COLLISION_GROUP_DOORS
	end
end

---------------------
-- Door setup
---------------------

local function isValidDoor(instance: Instance)
	return instance:IsA("Model") and instance:GetAttribute("__Door") == true
end

local function setupDoor(model: Instance)
	if not isValidDoor(model) then return end

	setDoorCollisionGroup(model :: Model)

	local door = Door.new(model :: Model, {
		Remotes = {
			Action = Remotes.Action;
			RequestState = Remotes.RequestState;
			SyncState = Remotes.SyncState;
		},
	})

	activeDoors[door:GetId()] = door
	return door
end

for _, child in Doors:GetChildren() do
	setupDoor(child)
end
Doors.ChildAdded:Connect(setupDoor)

------------------------------
-- Player collision groups
------------------------------

local function applyCollisionGroup(part: Instance)
	if part:IsA("BasePart") then
		part.CollisionGroup = COLLISION_GROUP_PLAYERS
	end
end

local function setupCharacter(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		applyCollisionGroup(part)
	end
	character.DescendantAdded:Connect(applyCollisionGroup)
end

local function setupPlayer(player: Player)
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

------------------------------
-- Client action requests
------------------------------

Remotes.Action.OnServerInvoke = function(player: Player, data: any)
	if typeof(data) ~= "table" or typeof(data.Id) ~= "string" then
		return { CODE = Door.Codes.INVALID_ACTION }
	end

	local door = activeDoors[data.Id]
	if not door then
		return { CODE = Door.Codes.DOOR_NOT_FOUND }
	end

	return door:Act(player, data)
end
