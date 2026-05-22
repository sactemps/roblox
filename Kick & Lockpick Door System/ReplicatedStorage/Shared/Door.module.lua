local CharmSync = require(game.ReplicatedStorage.Packages.CharmSync)
local Charm = require(game.ReplicatedStorage.Packages.Charm)

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local Door = {}

local NONE = {__none = "__none"}

Door.__index = Door

-- Codes used in identifying messages. Not always given: do not assume it will always be given.
Door.Codes = {
	STATE_UPDATE = "STATE_UPDATE";
	NEW_DOOR = "NEW_DOOR";
	READY = "READY";
	CANNOT_KICK = "CANNOT_KICK";
}
Door.Actions = {
	Kick = {
		Name = "Kick";
		Animation = Instance.new("Animation");
		AnimationId = "rbxassetid://136983861594940";
	},
	Lockpick = {
		Name = "Lockpick";
		Animation = Instance.new("Animation");
		AnimationId = "rbxassetid://117726443207384";
	}
}
Door.AtomMap = {
	Id = { _ID = true };
	Player = { DefaultValue = NONE };
	Locked = { DefaultValue = true };
	Open = { DefaultValue = false };
	BeingPicked = { DefaultValue = false, Action = Door.Actions.Lockpick.Name };
	BeingKicked = { DefaultValue = false, Action = Door.Actions.Kick.Name };
	Kicked = { DefaultValue = false };
	Cooldown = { DefaultValue = false };
	PickProgress = { DefaultValue = 0 };
}

Door._newdoorpayload = { CODE = Door.Codes.NEW_DOOR }
Door._stateupdatepayload = { CODE = Door.Codes.STATE_UPDATE }

function Door.new(model, options: any)
	assert(RunService:IsServer(), "Server-only function")
	
	assert(typeof(options) == "table", "Invalid options")
	assert(typeof(options.Remotes) == "table", "Missing remotes")
	
	local self = setmetatable({}, Door)	
		
	self.Model = model
	
	for atomName, properties in pairs(self.AtomMap) do
		if properties._ID then
			self[atomName] = Charm.atom(HttpService:GenerateGUID(false))
			continue	
		end
		
		self[atomName] = Charm.atom(properties.DefaultValue)
		
		if atomName == "Kicked" then
			local disconnect
			disconnect = Charm.subscribe(self[atomName], function(new, prev)
				if new and not prev then -- If the Kicked state changes from false to true then:
					self.Model.PrimaryPart.Anchored = false
					self.Model.Hinge.HingeConstraint.ServoMaxTorque = 0
					self.Model.PrimaryPart:ApplyAngularImpulse(Vector3.new(0, 150, 0))
					disconnect()
				end
			end)
		end
	end
	
	self._stateevent = options.Remotes.StateEvent
	
	-- Replace animations (by default: nil) with an Animation instance
	for k, actionData in pairs(self.Actions) do
		local animation = Instance.new("Animation")
		animation.AnimationId = actionData.AnimationId
		
		self.Actions[k].Animation = animation
	end
	
	self:AddToCollection("KickableDoors", "LockpickableDoors")
	self:StartSyncer(options.Remotes)
	
	return self
end

function Door:AddToCollection(...)
	assert(RunService:IsServer(), "Server-only function")

	if not ... then return end
	local collections = {...}
	
	for _, collection in ipairs(collections) do
		CollectionService:AddTag(self.Model, collection)
	end
end

function Door:RemoveFromCollection(...)
	assert(RunService:IsServer(), "Server-only function")

	if not ... then return end
	local collections = {...}
	
	for _, collection in ipairs(collections) do
		CollectionService:RemoveTag(self.Model, collection)
	end
end

function Door:action(plr: Player, data: any)
	assert(RunService:IsServer(), "Server-only function")

	assert(typeof(data) == "table", "Invalid data")

	if data.Id ~= self.Id() then
		return
	end

	print("EVENT RECIEVED")

	local rawAction = data.Action
	local action = Door.Actions[rawAction]

	assert(
		typeof(rawAction) == "string" and
			action,
		"Invalid action"
	)

	if self.Cooldown() then
		return {
			CODE = Door.Codes.ON_COOLDOWN
		}
	end

	if self.BeingKicked() or
		self.BeingPicked() or
		self.Kicked() then
		return {
			CODE = Door.Codes.CANNOT_KICK
		}
	end
	
	if action == Door.Actions.Kick then
		self:Kick(plr)
	elseif action == Door.Actions.Lockpick then
		self:StartLockpick(plr)
	end
end

function Door:StartLockpick(player)
	assert(RunService:IsServer(), "Server-only function")
	
	warn(`StartLockpick`)
	
	if not self.Locked() then return end
	if self.Cooldown() then return end
	
	self:RemoveFromCollection("KickableDoors", "LockpickableDoors")
	
	self.BeingPicked(true)
	
	task.spawn(function()
		for i = 1, 100 do
			if not self.BeingPicked() then return end
			
			self.PickProgress(i)
			
			task.wait(0.1)
		end
		
		self.Locked(false)
		self.BeingPicked(false)
		self.PickProgress(0)
	end)
end

function Door:Kick(player)
	assert(RunService:IsServer(), "Server-only function")
	
	warn(`Kick`)

	if not self.Locked() then return end
	if self.Cooldown() then return end
	
	self:RemoveFromCollection("KickableDoors", "LockpickableDoors")
	
	local character = player.Character
	local humanoid = nil
	local humanoidRootPart = nil
	
	xpcall(function()
		if character then
			humanoid = character:FindFirstChildWhichIsA("Humanoid")
			humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
		
		local playerPosition = self.Model:FindFirstChild("PlayerPosition")
		if playerPosition then
			humanoidRootPart.Anchored = true
			humanoidRootPart.CFrame = playerPosition.CFrame
		end
	end, function(err)
		warn(`Error during door kick: {err}`)
	end)
	
	Charm.batch(function()
		self.Player(player)
		self.Locked(false)
		self.Cooldown(true)
		self.BeingKicked(true)
	end)
	
	local _delay = Door.Actions.Kick.AnimationLength or 2
	
	task.delay(_delay, function()
		xpcall(function()
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
			
			humanoidRootPart.Anchored = false
		end, function(err)
			warn(`Error during door kick: {err}`)
		end)
		
		Charm.batch(function()
			self.Player(NONE)
			self.BeingKicked(false)
			self.Kicked(true)
			self.Cooldown(false)
		end)
	end)
end

-- Returns state data that can be securely replicated to client users.
function Door:GetSharableData()
	return {
		Model = self.Model;
		Id = self.Id();
		AtomMap = {
			Player = self.Player();
			Id = self.Id();
			Locked = self.Locked();
			Open = self.Open();
			BeingPicked = self.BeingPicked();
			BeingKicked = self.BeingKicked();
			Kicked = self.Kicked();
			Cooldown = self.Cooldown();
			PickProgress = self.PickProgress();
		}
	}
end

-- Returns atoms with values that can be securely replicated to clients.
function Door:GetSharableAtoms()
	return {
		Id = self.Id;
		Player = self.Player;
		Locked = self.Locked;
		Open = self.Open;
		BeingPicked = self.BeingPicked;
		BeingKicked = self.BeingKicked;
		Kicked = self.Kicked;
		Cooldown = self.Cooldown;
		PickProgress = self.PickProgress;
	}
end

-- Helper function to compress multiple tables into one.
function Door:Compress(...)
	local result = {}
	
	for _, item in ipairs({...}) do
		if typeof(item) == "table" then
			for key, value in pairs(item) do
				result[key] = value
			end
		end
	end
	
	return result
end

-- Returns the RemoteEvent associated with the door (or nil) and a boolean of whether or not the remote is "active" (can be fired)
function Door:GetStateRemote()
	assert(RunService:IsServer(), "Server-only function")

	local _stateevent = self._stateevent
	if typeof(_stateevent) == "Instance" and
		_stateevent:IsA("RemoteEvent") then
		return _stateevent, true
	end
	return nil, false
end

-- Deprecated
function Door:GetActionFunction()
	assert(RunService:IsServer(), "Server-only function")

	local _actionfunction = self._actionfunction
	if typeof(_actionfunction) == "Instance" and
		_actionfunction:IsA("RemoteFunction") then
		return _actionfunction, true
	end
	return nil, false
end

function Door:GetActionFromAtomName(name: string)
	return self.AtomMap[name].Action
end

-- Deprecated
function Door:UpdateAllClients(...)
	assert(RunService:IsServer(), "Server-only function")
	
	local additionalData = typeof(...) == "table" and ... or {}
	
	warn(`Pushing update`)
	
	local remote, exists = self:GetStateRemote()
	if exists then
		
		local sharable = self:GetSharableData()
		
		local payload = self:Compress(sharable, additionalData)
		
		remote:FireAllClients(payload)
	end
end

-- Deprecated
function Door:UpdateClient(plr: Player, ...)
	assert(RunService:IsServer(), "Server-only function")

	local additionalData = typeof(...) == "table" and ... or {}

	warn(`Pushing client update`)
	
	local remote, exists = self:GetStateRemote()
	if exists then
		remote:FireClient(plr,
			self:Compress(
				self:GetSharableData(),
				...
			)
		)
	end
end

-- Deprecated
function Door:UpdateOnPlayerJoin()
	assert(RunService:IsServer(), "Server-only function")

	game.Players.PlayerAdded:Connect(function(plr)
		self:UpdateClient(plr, self._newdoorpayload)
	end)
end

function Door:StartSyncer(remotes)
	assert(RunService:IsServer(), "Server-only function")
	
	local syncer = CharmSync.server({
		atoms = self:GetSharableAtoms(),
		interval = 0,
		preserveHistory = false,
		autoSerialize = true
	})
	
	self.__Syncer = syncer
	
	syncer:connect(function(plr, ...)
		remotes.SyncState:FireClient(plr, self:Compress({ Id = self.Id(), Model = self.Model }, ...))
	end)

	remotes.RequestState.OnServerEvent:Connect(function(plr)
		syncer:hydrate(plr)
	end)
end

-- Deprecated
function Door:StartRemotes(remotes)
	assert(RunService:IsServer(), "Server-only function")
end

return Door