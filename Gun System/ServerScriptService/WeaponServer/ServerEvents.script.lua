-- [[
--    ServerEvents.script.lua
--	  Hook client remotes to server logic.
--    
--    Made by sac_ie
--]]

-- hook (client) remotes to server logic

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local GunAssets = RS:WaitForChild("GunAssets")
local WeaponManager = require(script.Parent.WeaponManager)
local Tracers = game.Workspace:WaitForChild("Tracers")

local Remotes = RS:WaitForChild("Remotes")
local EquipWeapon = Remotes:WaitForChild("EquipWeapon")
local FireWeapon = Remotes:WaitForChild("FireWeapon")
local HitReport = Remotes:WaitForChild("HitReport")
local ReloadWeapon = Remotes:WaitForChild("ReloadWeapon")
local AimReport = Remotes:WaitForChild("AimReport")

local function errorHandler(err)
	return debug.traceback(err)
end

EquipWeapon.OnServerEvent:Connect(function(player: Player, weaponName: string, equipping: boolean)
	print(`EquipWeapon called with {weaponName} and {equipping}`)
	assert(typeof(weaponName) == 'string')
	
	if equipping then
		local character = player.Character
		assert(character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0)
				
		local slot = WeaponManager:AddWeapon(player, weaponName)
		WeaponManager:EquipSlot(player, slot)
	else
		WeaponManager:UnequipWeapon(player)
	end
end)

local maxPitch = math.rad(45)
local tweenTime = 0.15

AimReport.OnServerEvent:Connect(function(player, camCFrame)
	if not WeaponManager:IsPlayerWeaponEquipped(player) then return end
	
	local character = player.Character
	if not character then return end

	local upperTorso = character:FindFirstChild("UpperTorso")
	local head = character:FindFirstChild("Head")
	if not upperTorso or not head then return end

	local waist = upperTorso:FindFirstChild("Waist")
	local neck = head:FindFirstChild("Neck")
	if not waist or not neck then return end

	if not waist:GetAttribute("OriginalC1") then
		waist:SetAttribute("OriginalC1", waist.C1)
	end
	if not neck:GetAttribute("OriginalC1") then
		neck:SetAttribute("OriginalC1", neck.C1)
	end

	local waistOriginal = waist:GetAttribute("OriginalC1")
	local neckOriginal = neck:GetAttribute("OriginalC1")

	local cameraLook = camCFrame.LookVector
	local pitch = -math.asin(cameraLook.Y)
	pitch = math.clamp(pitch, -maxPitch, maxPitch)

	local waistGoal = { C1 = CFrame.Angles(pitch * 0.5, 0, 0) * waistOriginal }
	local neckGoal = { C1 = CFrame.Angles(pitch, 0, 0) * neckOriginal }

	TS:Create(waist, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), waistGoal):Play()
	TS:Create(neck, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), neckGoal):Play()

	local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
	local rightShoulder = upperTorso:FindFirstChild("RightShoulder")

	if leftShoulder and rightShoulder then
		if not leftShoulder:GetAttribute("OriginalC1") then
			leftShoulder:SetAttribute("OriginalC1", leftShoulder.C1)
		end
		if not rightShoulder:GetAttribute("OriginalC1") then
			rightShoulder:SetAttribute("OriginalC1", rightShoulder.C1)
		end

		local leftOriginal = leftShoulder:GetAttribute("OriginalC1")
		local rightOriginal = rightShoulder:GetAttribute("OriginalC1")

		local armTilt = pitch * 0.25
		local leftGoal = { C1 = CFrame.Angles(armTilt, 0, 0) * leftOriginal }
		local rightGoal = { C1 = CFrame.Angles(armTilt, 0, 0) * rightOriginal }

		TS:Create(leftShoulder, TweenInfo.new(tweenTime), leftGoal):Play()
		TS:Create(rightShoulder, TweenInfo.new(tweenTime), rightGoal):Play()
	end
end)

local FIRE_THRESHOLD = {
	LIMIT = 30;
	PER = 1;
}

local CURRENT_THRESHOLD = {}

task.spawn(function() -- Clear rate limits on 1 second inteval
	while task.wait(1) do
		CURRENT_THRESHOLD = {}
	end
end)

FireWeapon.OnServerEvent:Connect(function(plr, targetPosition)
	--print("EVENT")
	
	local character = plr.Character
	if not character then print("NO CHARACTER") return false end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then print("NO HUMANOID") return false end

	if humanoid.Health == 0 then print("HEALTH IS 0") return false end

	local rig = WeaponManager:GetRigFromPlayer(plr)
	if not rig then print("NO RIG") return false end
	
	if CURRENT_THRESHOLD[plr.UserId] then
		if CURRENT_THRESHOLD[plr.UserId] >= FIRE_THRESHOLD.LIMIT then
			print("RATE LIMIT EXCEEDED")
			return false
		else
			CURRENT_THRESHOLD[plr.UserId] += 1
		end
	else
		CURRENT_THRESHOLD[plr.UserId] = 1
	end
	
	if not WeaponManager:HasAboveOneAmmo(plr) then print("OUT OF AMMO") return false end
	
	WeaponManager:FireWeapon(plr)

	local function ValidateFireTarget()		
		local rayOrigin = rig:FindFirstChild("rayOrigin")
		if not rayOrigin then return false end
		
		local rayOriginPosition = rayOrigin.Position
		
		local rayDirection = (targetPosition - rayOriginPosition).Unit * 1000
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = true

		local result = workspace:Raycast(rayOriginPosition, rayDirection, raycastParams)
		return result, rayOrigin, rayDirection
	end

	local function BulletTracer(position)
		local rayOrigin = rig:FindFirstChild("rayOrigin")
		if not rayOrigin then return false end
		
		local att0 = rayOrigin:FindFirstChild("Attachment0")
		if not att0 then print("NO ATT0") return false end
		
		local att1 = rayOrigin:FindFirstChild("Attachment1")
		if not att1 then print("NO ATT1") return false end
		
		local beam = rayOrigin:FindFirstChildWhichIsA("Beam")
		if not beam then print("NO BEAM") return false end
		
		beam = beam:Clone()
		beam.Parent = Tracers

		local att0 = att0:Clone()
		local att1 = att1:Clone()
				
		att0.Parent = Tracers
		att1.Parent = Tracers
		
		att1.WorldPosition = position
		att0.WorldPosition = rayOrigin.Position
		
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		
		beam.Enabled = true
		
		beam.Name = plr.Name
		att0.Name = plr.Name
		att1.Name = plr.Name
		
		task.delay(0.06, function()
			beam.Enabled = false
			beam:Destroy()
			att0:Destroy()
			att1:Destroy()
		end)
	end
		
	if typeof(targetPosition) ~= "Vector3" and targetPosition ~= nil then return false end
	
	local result, rayOrigin, rayDirection = ValidateFireTarget()
	
	local tracer
	
	if result then
		--print("Got a hit")
		BulletTracer(result.Position)
	else -- Hit void (likely)
		--print("No hit")
		local missPosition = rayOrigin.Position + rayDirection * 300
		BulletTracer(missPosition)
	end
end)

ReloadWeapon.OnServerEvent:Connect(function(plr)
	WeaponManager:ReloadWeapon(plr)
end)

RunService.Heartbeat:Connect(function(_)	
	for player, data in WeaponManager:GetAllPlayersEquippedWeapons() do
		local success, errorMessage = xpcall(function()
			local character = player.Character
			if not character then print("Missing character"); return end

			local rig = WeaponManager:GetRigFromPlayer(player)
			if not rig then
				rig = WeaponManager:BindRig(player)
			end
			
			rig:PivotTo(character.Head.CFrame)
		end, errorHandler)

		if not success then
			warn("[WeaponServer] Error in ServerEvents:\n" .. errorMessage)
		end
	end
end)