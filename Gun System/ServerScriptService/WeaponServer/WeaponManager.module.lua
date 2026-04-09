-- authoritative server control, spawns weapon instances, manages ownership/state

local GunAssets = game.ReplicatedStorage:WaitForChild("GunAssets")

local WeaponManager = {}

WeaponManager.PlayerWeapons = {}

-- TODO (eventually): Make the WeaponData table easier to manage 

WeaponManager.WeaponData = {
	["Revolver"] = {
		FireRate = 0.25,
		AmmoMax = 6,
		Recoil = 1,
		ModelName = "RevolverModel"
	},
	["Big ahh gun"] = {
		FireRate = 0.01,
		AmmoMax = 600,
		Recoil = 0.2,
		ModelName = "Big ahh gun"
	}
}

-- Check if player is initialized in our system. If not, do it. Necessary for most calls here.
function WeaponManager:PreReq(player)
	local init = self:IsPlayerInit(player)
	if not init then
		init = self:InitPlayer(player)
	end
	return init
end

function WeaponManager:IsPlayerInit(player)
	--warn("IsPlayerInit")
	return self.PlayerWeapons[player]
end

function WeaponManager:InitPlayer(player)
	--warn("InitPlayer")
	self.PlayerWeapons[player] = {
		Slots = {},
		EquippedSlot = nil,
		EquippedWeapon = nil,
		Ammo = {},
	}
	return self:GetPlayer(player)
end

function WeaponManager:GetPlayer(player)
	local state = self:PreReq(player)
	return state
end

function WeaponManager:IsPlayerWeaponEquipped(player)
	self:PreReq(player)
	local state = self:PreReq(player)
	if state and state.EquippedWeapon then return true end
end

function WeaponManager:GetRigFromPlayer(player)
	--warn("GetRigFromPlayer")
	self:PreReq(player)
	local state = self:PreReq(player)
	if state then
		return state.Rig
	end
end

function WeaponManager:BindRig(player)
	warn("BindRig")
	local state = self:PreReq(player)
	if not state.EquippedWeapon then print("No data"); return end
	print(state.EquippedWeapon)
	local rig = self:GetTPRigFromName(state.EquippedWeapon):Clone()
	self:SetPlayerRig(player, rig)
	self.PlayerWeapons[player].Rig = rig
	return rig
end

function WeaponManager:SetPlayerRig(player, rig)
	rig.Name = player.Name
	rig.Parent = game.Workspace.VisibleWeaponViewModels
	self:MatchRigToPlayer(player, rig)
	
	local setCanCollide
	
	setCanCollide = function(basePart)
		for _, descendant in ipairs(basePart:GetDescendants()) do
			if descendant:IsA("BasePart") then
				setCanCollide(descendant)
				descendant.CanCollide = false
			end
		end
	end
	setCanCollide(rig)
end

function WeaponManager:UnbindRig(player)
	warn("UnbindRig")
	self:PreReq(player)
	local state = self:PreReq(player)
	if state and state.Rig then
		state.Rig = nil
	end
end

function WeaponManager:MatchRigToPlayer(player, rig)
	local rig = rig or self:GetRigFromPlayer(player)
	if not rig then return end
	
	local character = player.Character or player.CharacterAdded:Wait()

	local bodyColors = character["Body Colors"]
	local shirt = character:FindFirstChild("Shirt")

	if not shirt or not bodyColors then return end

	shirt:Clone().Parent = rig
	bodyColors:Clone().Parent = rig	
end

function WeaponManager:GetTPRigFromName(rigName)
	--warn("GetTPRigFromName")
	local hlRig = GunAssets:FindFirstChild(rigName)
	local tpRig
	if hlRig then
		tpRig = hlRig:FindFirstChild("ViewTPModel")
	end
	return tpRig
end

function WeaponManager:GetAllPlayersEquippedWeapons()
	--warn("GetAllPlayersEquippedWeapons")
	local data = {}
	for player, weaponData in self.PlayerWeapons do
		data[player] = {
			EquippedSlot = weaponData.EquippedSlot,
			EquippedWeapon = weaponData.EquippedWeapon
		}
	end
	return data
end

function WeaponManager:GetEquippedWeapon(player)
	--warn("GetEquippedWeapon")
	self:PreReq(player)
	local state = self:PreReq(player)
	return state and state.EquippedWeapon or nil
end

function WeaponManager:AddWeapon(player, weaponName)
	--warn("AddWeapon")
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state then return end
	
	for slot = 1, 3 do
		if not state.Slots[slot] then
			state.Slots[slot] = weaponName
			state.Ammo[weaponName] = self.WeaponData[weaponName].AmmoMax
			return slot
		end
	end
	return nil
end

function WeaponManager:EquipSlot(player, slot)
	--warn("EquipSlot")
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state then print("No state"); return end
	local weaponName = state.Slots[slot]
	if not weaponName then print("No weapon name") return end
	
	self:UnequipWeapon(player)
		
	state.EquippedSlot = slot
	state.EquippedWeapon = weaponName
		
	return true
end

function WeaponManager:UnequipWeapon(player)
	--warn("UnequipWeapon")
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state then print("No state") return end
	
	state.EquippedWeapon = nil
	state.EquippedSlot = nil
end

function WeaponManager:FireWeapon(player)
	--warn("FireWeapon")
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state then return end
	
	local weaponName = state.EquippedWeapon
	local ammo = state.Ammo[weaponName]
	if ammo <= 0 then return end
	
	state.Ammo[weaponName] = ammo - 1
		
	return true
end

function WeaponManager:HasAboveOneAmmo(player)
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state then return false end
	
	local weaponName = state.EquippedWeapon
	local ammo = state.Ammo[weaponName]
	return ammo > 0
end

function WeaponManager:ReloadWeapon(player)
	self:PreReq(player)
	local state = self:PreReq(player)
	if not state or not state.EquippedWeapon then return end
	
	local weaponName = state.EquippedWeapon
	state.Ammo[weaponName] = self.WeaponData[weaponName].AmmoMax
	
	return true
end

return WeaponManager