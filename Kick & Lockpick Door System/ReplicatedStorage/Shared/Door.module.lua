-- Author: sac_ie

local CharmSync = require(game.ReplicatedStorage.Packages.CharmSync)
local Charm = require(game.ReplicatedStorage.Packages.Charm)
local atom = Charm.atom

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local IS_SERVER = RunService:IsServer()

local Door = {}
Door.__index = Door

Door.NONE = {__none = "__none"}

Door.Codes = {
	STATE_UPDATE   = "STATE_UPDATE";
	NEW_DOOR       = "NEW_DOOR";
	READY          = "READY";
	CANNOT_ACT     = "CANNOT_ACT";
	ACTION_SUCCESS = "ACTION_SUCCESS";
	ON_COOLDOWN    = "ON_COOLDOWN";
	DOOR_NOT_FOUND = "DOOR_NOT_FOUND";
	INVALID_ACTION = "INVALID_ACTION";
}

-- Single source of truth for every field a door's atom starts with.
-- `Action` links a transient flag (e.g. BeingKicked) to the action whose
-- animation should play while that flag is true.
Door.AtomMap = {
	Id 			  = { Default = nil };
	Model         = { Default = nil };
	Player 		  = { Default = Door.NONE };
	Locked        = { Default = true };
	Open          = { Default = false };
	Peeking       = { Default = false };
	BeingPicked   = { Default = false, Action = "Lockpick" };
	BeingKicked   = { Default = false, Action = "Kick" };
	BeingKickedLP = { Default = false, Action = "KickOpen" };
	Kicked        = { Default = false };
	Cooldown      = { Default = false };
	PickProgress  = { Default = 0 };
}

local function buildDefaultState()
	local state = {}
	for key, meta in pairs(Door.AtomMap) do
		state[key] = meta.Default
	end
	return state
end

---------------------------------
-- Actions
---------------------------------

local function isIdle(state)
	return not state.BeingKicked and not state.BeingPicked
end
	
Door.Actions = {}

Door.Actions.Kick = {
	Name = "Kick";
	Key = Enum.KeyCode.R;
	AnimationId = "rbxassetid://136983861594940";
	Animation = nil;
	AnimationLength = 2;
	
	Requires = function(state)
		return state.Locked == true
			and not state.Cooldown
			and not state.Kicked
			and isIdle(state)
	end;
	
	Perform = function(door, player)
		door:_kickSequence(player)
	end,
}

Door.Actions.Lockpick = {
	Name = "Lockpick";
	Key = Enum.KeyCode.E;
	AnimationId = "rbxassetid://117726443207384";
	Animation = nil;

	Requires = function(state)
		return state.Locked == true
			and not state.Cooldown
			and not state.Kicked
			and isIdle(state)
	end;

	Perform = function(door, player)
		door:_lockpickSequence(player)
	end;
}

-- Lockpick Sub-action
Door.Actions.Peek = {
	Name = "Peek";
	Key = Enum.KeyCode.F;
	AnimationId = nil;
	Animation = nil;

	Requires = function(state)
		print(state.Locked == false)
		print(state.Kicked == false)
		print(state.Open == false)
		print(isIdle(state))
		
		return state.Locked == false
			and state.Kicked == false
			and state.Open == false
			and state.Peeking == false
			and isIdle(state)
	end;

	Perform = function(door, player)
		door:_peekSequence(player)
	end;
}

-- Lockpick Sub-action
Door.Actions.StopPeeking = {
	Name = "StopPeeking";
	Key = Enum.KeyCode.F;
	AnimationId = nil;
	Animation = nil;
	
	Requires = function(state)
		return state.Locked == false
			and state.Kicked == false
			and state.Open == false
			and state.Peeking == true
			and isIdle(state)
	end;
	
	Perform = function(door, player)
		door:_peekSequence(player)
	end,
}

-- Lockpick Sub-action
Door.Actions.KickOpen = {
	Name = "KickOpen";
	Key = Enum.KeyCode.Q;
	AnimationId = "rbxassetid://136983861594940";
	Animation = nil;
	AnimationLength = 1;

	Requires = function(state)
		return state.Locked == false
			and state.Kicked == false
			and state.Open == false
			and state.Peeking == false
			and not state.Cooldown
			and isIdle(state)
	end;

	Perform = function(door, player)
		door:_kickOpenSequence(player)
	end;
}

-- Load animations
for _, actionData in pairs(Door.Actions) do
	if actionData.AnimationId then
		local animation = Instance.new("Animation")
		animation.AnimationId = actionData.AnimationId
		actionData.Animation = animation
	end
end


------------------------------------
-- The module
------------------------------------

function Door.new(model: Model, options: any)
	assert(IS_SERVER, "Server-only function")
	assert(typeof(options) == "table", "Invalid options")
	assert(typeof(options.Remotes) == "table", "Missing options.Remotes")
	
	local self = setmetatable({}, Door)	
	self.Remotes = options.Remotes

	local initial = buildDefaultState()
	initial.Id = HttpService:GenerateGUID(false)
	initial.Model = model
	
	self.State = atom(initial)
	
	model:SetAttribute("id", self:GetId())
	
	self:_startSyncer({ self.State })
	self:_watchStateChanges()
	
	CollectionService:AddTag(model, "Doors")
	
	return self
end

------------------------
-- Accessor functions
------------------------

function Door:GetId()
	return self.State().Id
	
end

function Door:GetModel()
	return self.State().Model
end

function Door:GetCooldown()
	return self.State().Cooldown
	
end

--------------------------
-- State changes
--------------------------

function Door:UpdateState(patch)
	assert(IS_SERVER, "Server-only function")
	
	local current = self.State()
	local updated = table.clone(current)
	
	for k, v in pairs(patch) do
		updated[k] = v
	end
	
	self.State(updated)
end

----------------------------------
-- Sync merges
----------------------------------

function Door.Merge(...)
	local result = {}
	for _, item in ipairs({ ... }) do
		if typeof(item) == "table" then
			for key, value in pairs(item) do
				result[key] = value
			end
		end
	end
	return result
end

--------------------------------------
-- Client entry point for actions
--------------------------------------

function Door:Act(player: Player, data: any)
	assert(IS_SERVER, "Server-only function")
	assert(typeof(data) == "table", "Invalid data")
	
	if data.Id ~= self:GetId() then
		return { CODE = Door.Codes.DOOR_NOT_FOUND }
	end
	
	local actionName = data.Action
	local action = typeof(actionName) == "string" and Door.Actions[actionName]

	if not action then
		return { CODE = Door.Codes.INVALID_ACTION }
	end

	if self:GetCooldown() then
		return { CODE = Door.Codes.ON_COOLDOWN }
	end

	if not action.Requires(self.State()) then
		return { CODE = Door.Codes.CANNOT_ACT }
	end

	action.Perform(self, player)

	return { CODE = Door.Codes.ACTION_SUCCESS }
end

---------------------------------
-- Actions
---------------------------------

function Door:_lockpickSequence(player)
	self:UpdateState({ BeingPicked = true })
	
	task.spawn(function()
		for i = 1, 100 do
			print(i)
			if not self.State().BeingPicked then return end
			
			self:UpdateState({ PickProgress = i })
			task.wait(0.001)
		end
		
		print(1)
		
		self:UpdateState({
			Locked = false;
			BeingPicked = false;
			PickProgress = 0;
		})
		
		print(self.State().Locked)
	end)
end

function Door:_kickSequence(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	local ok, err = pcall(function()
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end

		local playerPosition = self:GetModel():FindFirstChild("PlayerPosition")
		if playerPosition and rootPart then
			rootPart.Anchored = true
			rootPart.CFrame = playerPosition.CFrame
		end
	end)
	if not ok then warn(`Error during door kick setup: {err}`) end

	self:UpdateState({
		Player = player;
		Locked = false;
		Cooldown = true;
		BeingKicked = true;
	})

	local duration = Door.Actions.Kick.AnimationLength or 2

	task.delay(duration, function()
		local ok2, err2 = pcall(function()
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
			if rootPart then
				rootPart.Anchored = false
			end
		end)
		if not ok2 then warn(`Error resetting player after kick: {err2}`) end

		self:UpdateState({
			Player = Door.NONE;
			BeingKicked = false;
			Kicked = true;
			Open = true;
			Cooldown = false;
		})
	end)
end

function Door:_peekSequence(player)
	self:UpdateState({ Peeking = not self.State().Peeking })
end

function Door:_kickOpenSequence(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	local ok, err = pcall(function()
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end

		local playerPosition = self:GetModel():FindFirstChild("PlayerPosition")
		if playerPosition and rootPart then
			rootPart.Anchored = true
			rootPart.CFrame = playerPosition.CFrame
		end
	end)
	if not ok then warn(`Error during door kick open setup: {err}`) end

	self:UpdateState({
		Player = player;
		Cooldown = true;
		BeingKickedLP = true;
	})
	
	local duration = Door.Actions.KickOpen.AnimationLength or 1

	task.delay(duration, function()
		local ok2, err2 = pcall(function()
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
			if rootPart then
				rootPart.Anchored = false
			end
		end)
		
		if not ok2 then warn(`Error resetting player after kick open: {err2}`) end

		self:UpdateState({
			Player = Door.NONE;
			Open = true;
			Cooldown = false;
			BeingKickedLP = false;
		})
	end)
end

--------------------------------------------------------------------------
-- Physical state change effects
--------------------------------------------------------------------------

local function getHinge(model: Model)
	local primary = model.PrimaryPart
	local hingePart = model:FindFirstChild("Hinge")
	local constraint = hingePart and hingePart:FindFirstChildWhichIsA("HingeConstraint")

	if primary and primary:IsA("BasePart") and constraint then
		return primary, constraint
	end
	return nil, nil
end

function Door:_watchStateChanges()
	Charm.subscribe(self.State, function(state, prev)
		local diff = {}
		for key, val in pairs(state) do
			if prev[key] ~= val then
				diff[key] = val
			end
		end

		local model = self:GetModel()
		local primary, hinge = getHinge(model)
		if not primary or not hinge then return end
		
		-- Door kicked
		if diff.Kicked == true then
			print("Kicking the door open")
			primary.Anchored = false
			hinge.ServoMaxTorque = 0
			primary:ApplyAngularImpulse(Vector3.new(0, 180, 0))
		end
		
		-- Peeking the door open
		if diff.Peeking ~= nil and not state.Kicked then
			print("Peeking through the door")
			primary.Anchored = false
			hinge.ActuatorType = Enum.ActuatorType.Servo
			hinge.ServoMaxTorque = 5000
			hinge.AngularSpeed = 4
			hinge.TargetAngle = diff.Peeking and 15 or 0
		end
		
		-- Kick the door fully open
		if diff.Open == true and not state.Kicked then
			print("Kicking fully open")
			primary.Anchored = false
			hinge.ServoMaxTorque = 0
			primary:ApplyAngularImpulse(Vector3.new(0, 180, 0))
		end
	end)
end

---------------------------
-- Networking
---------------------------

function Door:_startSyncer(atoms)
	local syncer = CharmSync.server({
		atoms = atoms,
		interval = 0,
		preserveHistory = false,
		autoSerialize = true,
	})

	self.__Syncer = syncer

	syncer:connect(function(player, ...)
		-- `...` must stay last in the call to expand fully
		local payloads = { ... }
		table.insert(payloads, { Id = self:GetId() })
		self.Remotes.SyncState:FireClient(player, Door.Merge(table.unpack(payloads)))
	end)

	self.Remotes.RequestState.OnServerEvent:Connect(function(player, doorId)
		if doorId ~= self:GetId() then return end
		syncer:hydrate(player)
	end)
end

return Door
