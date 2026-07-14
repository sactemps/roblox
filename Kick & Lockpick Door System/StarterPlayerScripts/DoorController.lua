-- Author: sac_ie

local Door = require(game.ReplicatedStorage.Shared.Door)

local Charm = require(game.ReplicatedStorage.Packages.Charm)
local CharmSync = require(game.ReplicatedStorage.Packages.CharmSync)
local atom = Charm.atom

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = game.Players.LocalPlayer
local Remotes = game.ReplicatedStorage.Remotes.Doors

local DISTANCE = 5
local POLL_INTERVAL = 0.5
local INPUT_DEBOUNCE = 0.5

-----------------------------
-- Door states keyed by ID
-----------------------------

local doorStates = {} --[id] = { Model, Syncer, Atom } 

--task.spawn(function()
--	while true do
--		task.wait(1)
		
--		for id, entry in pairs(doorStates) do
--			print(entry.Atom())
--		end
--	end
--end)

local function getStateByModel(model: Model)
	for id, entry in pairs(doorStates) do
		if entry.Model == model then
			return id, entry
		end
	end
	return nil, nil
end

local function playActionFeedback(flagName: string, player: Player)
	local meta = Door.AtomMap[flagName]
	local action = meta and meta.Action and Door.Actions[meta.Action]
	if not action or not action.Animation then return end
	
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")
	if not animator then return end
	
	local track = animator:LoadAnimation(action.Animation)
	track.Looped = false
	track:Play()
end

function subscribeToDoorAtom(doorAtom: Charm.Atom<any>)	
	Charm.subscribe(doorAtom, function(state, prev)
		for key, val in pairs(state) do
			if prev[key] ~= val and val == true then
				if Door.AtomMap[key] and Door.AtomMap[key].Action then
					playActionFeedback(key, state.Player)
				end
			end
		end
	end)
end

Remotes.SyncState.OnClientEvent:Connect(function(payload)	
	local id = payload.Id
	assert(id, "Sync payload missing ID")
	
	local kind = payload.type
	
	if kind == "init" then
		local data = payload.data[1]
		
		local doorAtom = atom(data)
		local syncer = CharmSync.client({
			atoms = { doorAtom },
			ignoreUnhydrated = false
		})

		doorStates[id] = {
			Model = data.Model,
			Syncer = syncer,
			Atom = doorAtom
		}

		subscribeToDoorAtom(doorAtom)
	elseif kind == "patch" then
		local entry = doorStates[id]
		if not entry then 
			warn(`Patch received for unknown door {id}`)
			return
		end
		
		entry.Syncer:sync(payload)
	end
end)

CollectionService:GetInstanceAddedSignal("Doors"):Connect(function(instance)
	Remotes.RequestState:FireServer(instance:GetAttribute("id"))
end)

local selected = {
	Model = nil :: Model?,
	Id = nil :: string?,
	Interactions = {} :: { [string]: { Key: Enum.KeyCode, Callback: () -> (), Exhausted: boolean } };
}

local function setPromptVisible(door: Model, actionName: string, visible: boolean)
	local folder = door:FindFirstChild("Interactions")
	local node = folder and folder:FindFirstChild(actionName)
	if not node then return end
	
	local hint = node:FindFirstChild("HintPart")
	local gui = node:FindFirstChild("InteractionGui")
	
	if hint then hint.Transparency = visible and 0 or 1 end
	if gui then
		gui.Enabled = visible
		local keyLabel = gui:FindFirstChild("KeyFrame") and gui.KeyFrame:FindFirstChild("Key") or gui:FindFirstChild("Key")
		if visible and keyLabel then
			keyLabel.Text = Door.Actions[actionName].Key.Name
		end
	end
end

local function clearInteractions()
	if selected.Model then
		for actionName in pairs(selected.Interactions) do
			setPromptVisible(selected.Model, actionName, false)
		end
	end
	selected.Interactions = {}
end

local function setInteraction(door: Model, actionName: string, callback: () -> ())
	selected.Interactions[actionName] = {
		Key = Door.Actions[actionName].Key;
		Callback = callback;
		Exhausted = false;
	}
	setPromptVisible(door, actionName, true)
end

-------------------------------------------
-- Actions that are allowed for a given door's state
-------------------------------------------

local function getAvailableActions(stateData)
	local available = {}
	--print(stateData)
	for name, action in pairs(Door.Actions) do
		if action.Requires(stateData) then
			table.insert(available, name)
		end
	end
	return available
end

--------------------------------------------
-- Proximity loop
--------------------------------------------

task.spawn(function()
	while true do
		task.wait(POLL_INTERVAL)
		
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		
		local closestModel, closestId, closestEntry, closestDist
		
		for _, model in ipairs(CollectionService:GetTagged("Doors")) do
			local primary = model.PrimaryPart
			if not primary then return end
			
			local dist = (primary.Position - root.Position).Magnitude
			--print(dist)
			
			if dist < DISTANCE and (not closestDist or dist < closestDist) then
				--print(1)
				local id, entry = getStateByModel(model)
				if id then
					closestModel, closestId, closestEntry, closestDist = model, id, entry, dist
				end
			end
		end
		
		if closestModel ~= selected.Model then
			clearInteractions()
			selected.Model = closestModel
			selected.Id = closestId
		end
		
		if not selected.Model then continue end
		
		local stateData = closestEntry.Atom()
		local legal = getAvailableActions(stateData)
		
		local legalSet = {}
		for _, name in ipairs(legal) do legalSet[name] = true end
		
		for name in pairs(selected.Interactions) do
			if not legalSet[name] then
				setPromptVisible(selected.Model, name, false)
				selected.Interactions[name] = nil
			end
		end
		
		for _, name in ipairs(legal) do
			if not selected.Interactions[name] then
				setInteraction(selected.Model, name, function()
					Remotes.Action:InvokeServer({ Id = selected.Id, Action = name })
				end)
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not selected.Model then return end
	
	for name, interaction in pairs(selected.Interactions) do
		if interaction.Key == input.KeyCode and not interaction.Exhausted then
			interaction.Exhausted = true
			interaction.Callback()
			task.delay(INPUT_DEBOUNCE, function()
				if selected.Interactions[name] then
					selected.Interactions[name].Exhausted = false
				end
			end)
		end
	end
end)
