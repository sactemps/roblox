local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Charm = require(game.ReplicatedStorage.Packages.Charm)
local CharmSync = require(game.ReplicatedStorage.Packages.CharmSync)

local Door = require(game.ReplicatedStorage.Shared.Door)

local Remotes = game.ReplicatedStorage.Remotes.Doors

local DoorsWithInteractions = {}

local __DoorStates = {}

local DoorStates = setmetatable({}, {
	__index = __DoorStates,
	__newindex = function(_, k, v)
		__DoorStates[k] = v
	end,
})

-- Returns the first instance where key.Model == model, from DoorStates
function GetStateFromModel(model: Model)
	for id, data in pairs(__DoorStates) do
		if data.Model == model then
			return { Id = id, data = data }
		end
	end
end

-- Power house of starting animations & similar on the client
function SubscribeToAtom(doorId: any, actionName: any, atom: any)
	if typeof(actionName) ~= "string" then return print("NOT STRING") end
	
	local action = Door.Actions[actionName]
	if not action then return print("NOT FOUND") end
	
	local animation = action.Animation
	
	print(`Starting subscriber for {actionName} ({atom()})`)
	
	 Charm.subscribe(atom, function(state, prev)
		print(`Subscriber hit for {actionName}`)
		print(`{state} {prev}`)
				
		local state = DoorStates[doorId]
		
		local player = state.Atoms.Player()
		if CharmSync.isNone(player) or player == nil then
			return print("PLAYER NOT FOUND")
		end
		
		print(player)
		
		local character = player.Character
		print(character)
		if not character then return end
		
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		print(humanoid)
		if not humanoid then return end
		
		local animator = humanoid:FindFirstChild("Animator")
		
		animation.AnimationId = action.AnimationId
		
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack.Looped = false
		
		animationTrack:Play()
	end)
	
end

Remotes.SyncState.OnClientEvent:Connect(function(...)	
	local payload = ...
	
	local id = payload.Id
	
	assert(id)
		
	local data = payload.data
	local type = payload.type
	
	if type == "init" then
		local model = payload.Model
		
		local atoms = {
			Id = Charm.atom(),
			Player = Charm.atom(),
			Locked = Charm.atom(),
			Open = Charm.atom(),
			BeingPicked = Charm.atom(),
			BeingKicked = Charm.atom(),
			Kicked = Charm.atom(),
			Cooldown = Charm.atom(),
			PickProgress = Charm.atom(),
		}

		local syncer = CharmSync.client({
			atoms = atoms,
			ignoreUnhydrated = false
		})

		DoorStates[id] = {
			Model = model,
			Syncer = syncer,
			Atoms = atoms
		}
		
		for name, atom in pairs(atoms) do
			local action = Door.AtomMap[name].Action
			if action then
				print(action)
				SubscribeToAtom(id, action, atom)
			end
		end
 	elseif type == "patch" then
		local state = DoorStates[id]
		if not state then return print("no state") end
		
		local syncer = state.Syncer
		if not syncer then return print("no syncer") end
		
		print(data)
		
		syncer:sync(...)
	end
end)

local selectedDoor = {
	Door = nil;
	Interactions = {
		--EXAMPLE = {
		--	Key = nil;
		--	Callback = nil;
		--  Exhausted = false;
		--  Gui = nil;
		--  Hint = nil;
		--}
	}
}

-- Pass the name of the interaction. Pass `true` to remove all interactions.
function RemoveInteraction(nameOrAll: string | true)
	assert(selectedDoor, "Can't remove an interaction without a door selected")
	
	local model = selectedDoor.Model
	local interactions = selectedDoor.Interactions
	
	if nameOrAll == true then
		for _, interaction in pairs(selectedDoor.Interactions) do
			if interaction.Gui then interaction.Gui.Enabled = false end
			if interaction.Hint then interaction.Hint.Transparency = 1 end
		end
		selectedDoor.Interactions = {}
	elseif nameOrAll ~= nil then
		if interactions[nameOrAll].Gui then interactions[nameOrAll].Gui.Enabled = false end
		if interactions[nameOrAll].Hint then interactions[nameOrAll].Hint.Transparency = 1 end
		interactions[nameOrAll] = nil
	end
end

function AddInteraction(name: string, key: string, callback)
	assert(selectedDoor, "Can't add an interaction without a door selected")
	
	local model = selectedDoor.Model
	local interactions = selectedDoor.Interactions
	
	interactions[name] = {
		Key = key;
		Callback = callback;
		Exhausted = false;
		Gui = nil;
		Hint = nil;
	}
end

local DISTANCE = 5

RunService.RenderStepped:Connect(function()
	local character = game.Players.LocalPlayer.Character
	local humanoidRootPart = character and character.HumanoidRootPart or nil
	
	local _doors = {
		Kickable = CollectionService:GetTagged("KickableDoors"),
		Lockpickable = CollectionService:GetTagged("LockpickableDoors")
	}
	local doors = {}
	
	-- Make doors directly indexable by model, rather than index. For practical purposes.
	for section, __doors in pairs(_doors) do
		doors[section] = {}
		for _, door in ipairs(__doors) do
			doors[section][door] = true
		end
	end
	
	local combined = Door:Compress(doors.Kickable, doors.Lockpickable)
		
	if selectedDoor.Door then
		if not combined[selectedDoor.Door] then RemoveInteraction(true); print("Removing all")
		
		elseif not doors.Kickable[selectedDoor.Door] then RemoveInteraction("Kick"); print("Not kickable")
		elseif not doors.Lockpickable[selectedDoor.Door] then RemoveInteraction("Lockpick"); print("Not lockpickable")
		end	
	end
	
	local closestDoor = {
		Door = nil,
		Distance = nil,
	}
	local doorsWithinDistance = {}
	
	-- Find doors that are within distance and can be interacted with
	for door, _ in pairs(combined) do
		local state = GetStateFromModel(door)
		if not state then continue end
		
		if character and humanoidRootPart then
			local primaryPart = door.PrimaryPart
			if not primaryPart then continue end
			
			local dist = (primaryPart.Position - humanoidRootPart.Position).Magnitude
			
			if dist < DISTANCE then
				if closestDoor.Door then
					if dist < closestDoor.Distance then
						closestDoor.Door = door
						closestDoor.Distance = dist
						closestDoor.State = state
					end
				else
					closestDoor.Door = door
					closestDoor.Distance = dist
					closestDoor.State = state
				end
			end
		end
	end
	
	if not closestDoor.Door then
		RemoveInteraction(true)
		selectedDoor.Door = nil
	else
		local door = closestDoor.Door
		local state = closestDoor.State
		if selectedDoor.Door ~= door then
			RemoveInteraction(true)
			selectedDoor.Door = door
			
			if doors.Kickable[door] then
				print("Kickable")
				AddInteraction("Kick", Enum.KeyCode.R, function()
					print(Remotes.Action:InvokeServer({ Id = state.Id, Action = "Kick" }))
				end)
			end
			if doors.Lockpickable[door] then
				print("Lockpickable")
				AddInteraction("Lockpick", Enum.KeyCode.E, function()
					print(Remotes.Action:InvokeServer({ Id = state.Id, Action = "Lockpick" }))
				end)
			end
		end
	end
	
	pcall(function()
		if selectedDoor.Door then
			local door = selectedDoor.Door
			
			local interactionFolder = door.Interactions
			if not interactionFolder then return end
			
			for name, data in pairs(selectedDoor.Interactions) do
				local specific = interactionFolder[name]
				if not specific then continue end
				
				local hintPart = specific:FindFirstChild("HintPart")
				local gui = specific.InteractionGui
				
				if not gui or not gui:IsA("BillboardGui") then return end
				
				data.Gui = gui
				data.Hint = hintPart
				
				if data.Exhausted then
					gui.Enabled = false
					hintPart.Transparency = 1
				else
					if hintPart then
						hintPart.Transparency = 0
					end
					gui.Key.Text = data.Key.Name
					gui.Enabled = true
				end
			end
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not selectedDoor.Door then return end
		
	for name, data in pairs(selectedDoor.Interactions) do
		if data.Key == input.KeyCode then 
			if data.Exhausted then return end
			data.Exhausted = true
			data.Callback()
		end
	end
end)

task.spawn(function()
	repeat task.wait() until game:IsLoaded() do end
	
	Remotes.RequestState:FireServer()
end)