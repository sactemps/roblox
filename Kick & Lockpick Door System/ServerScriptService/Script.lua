local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Provider = game:GetService("KeyframeSequenceProvider")
local PhysicsService = game:GetService("PhysicsService")
local ContentProvider = game:GetService("ContentProvider")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = RS:WaitForChild("Remotes")
local Doors = game.Workspace:WaitForChild("Doors")
local Modules = ServerScriptService:WaitForChild("Modules")

local Door = require(RS.Shared.Door)

local COLLISION_GROUP_DOORS = "Doors"
local COLLISION_GROUP_PLAYERS = "Players"

local REMOTE_DOOR_STATE = Remotes.Doors.State
local REMOTE_ACTION = Remotes.Doors.Action
local REMOTE_REQUEST_STATE = Remotes.Doors.RequestState
local REMOTE_SYNC_STATE = Remotes.Doors.SyncState

local doors = {}

-- Preload animations
pcall(function()
	local toload = {}
	
	for action, actionData in pairs(Door.Actions) do
		local animation = actionData.Animation
		local animationId = actionData.AnimationId
		
		if not animation or not animationId then continue end
		
		animation.AnimationId = animationId
		table.insert(toload, animation)
		
		local sequence = Provider:GetKeyframeSequenceAsync(animationId)
		local keyframes = sequence:GetKeyframes()
		
		local length = 0
		for i = 1, #keyframes do
			if keyframes[i].Time > length then
				length = keyframes[i].Time
			end
		end
		
		sequence:Destroy()
		
		actionData.AnimationLength = length
	end
	
	ContentProvider:PreloadAsync(toload)	
end)

pcall(function()
	PhysicsService:CollisionGroupSetCollidable(
		COLLISION_GROUP_DOORS,
		COLLISION_GROUP_PLAYERS,
		true
	)
end)

REMOTE_ACTION.OnServerInvoke = function(plr: Player, data: any)
	assert(typeof(data) == "table")
	
	local id = data.Id
	assert(typeof(id) == "string")
	
	local door = doors[id]
	if not door then return "Door not found" end
	
	door:action(plr, data)
end

function setDoorCollisionGroup(door: Model)
	if typeof(door) == Instance
		and door:IsA("Model")
		and door.PrimaryPart then
		primaryPart.CollisionGroup = COLLISION_GROUP_DOORS
	end
end

function setupDoor(door: Model)
	if not isValidDoor(door) then return end
	
	setDoorCollisionGroup(door)
	
	local door = Door.new(door, {
		Remotes = {
			Action = REMOTE_ACTION;
			StateEvent = REMOTE_DOOR_STATE;
			RequestState = REMOTE_REQUEST_STATE;
			SyncState = REMOTE_SYNC_STATE;
		}
	})
	
	doors[door.Id()] = door
	
	return door
end

function setupCharacter(character)
	local function apply(part)
		if typeof(part) == "Instance"
			and part:IsA("BasePart") then
			part.CollisionGroup = COLLISION_GROUP_PLAYERS
		end
	end
	
	if typeof(character) == "Instance" then
		for _, part in character:GetDescendants() do
			apply(part)
		end
		
		character.DescendantAdded:Connect(apply)
	end	
end

function setupPlayer(player)
	player.CharacterAdded:Connect(setupCharacter)
end

function isValidDoor(door: Model)
	if typeof(door) ~= "Instance"
		and not door:IsA("Model") then
		return false
	end
		
	local isDoor = door:GetAttribute("__Door")
	if not isDoor then return false end
	
	return true
end

for _, child in Doors:GetChildren() do setupDoor(child) end
Doors.ChildAdded:Connect(setupDoor)

Players.PlayerAdded:Connect(setupPlayer)