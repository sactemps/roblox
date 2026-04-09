-- [[
--    ViewmodelHandler.client.lua
--    This is the heart of the client-side system.
--    
--    Made by sac_ie
--]]

local AimZoomTimeFirstPerson = 0.05
local AimTimeFirstPerson = 0.45

local uis = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local slots = require(RS.GunConfigs.Slots)
local RunService = game:GetService("RunService")
local CameraController = require(RS.ClientModules:WaitForChild("CameraController"))
local Shared = require(script.Parent.Shared)
local Remotes = RS:WaitForChild("Remotes")

local Tracers = game.Workspace:WaitForChild("Tracers")

local player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")
local defaultZoom = {
	Min = player.CameraMinZoomDistance,
	Max = player.CameraMaxZoomDistance
}
local mouse = player:GetMouse()

local ViewModel
local CurrentGunName
local aiming = false
local equipped = Shared.equipped

local swayAmount = 0.10
local swayCF = CFrame.new()
local lastCameraCF = CFrame.new()
local aimCF = CFrame.new()

local bindableFire = RS.Bindable:WaitForChild("BindableFire")
local bindableReload = RS.Bindable:WaitForChild("BindableReload")
local bindableAim = RS.Bindable:WaitForChild("BindableAim")
local bindableEquip = RS.Bindable:WaitForChild("BindableEquip")

local ReloadWeapon = RS.Remotes:WaitForChild("ReloadWeapon")

local function createFPVModel()
	local viewModel = ViewModel:Clone()
	viewModel.Name = "ViewModel" .. CurrentGunName
	viewModel.Parent = Camera
	_G.MatchArmsToPlayer(viewModel, player)
end

local function destroyFPViewModel()
	local viewModel = Camera:FindFirstChild("ViewModel" .. CurrentGunName)
	if viewModel then viewModel:Destroy() end
end

local function SetArmsTransparency(player, transparency)
	local parts = {
		"LeftUpperArm";
		"LeftLowerArm";
		"LeftHand";

		"RightUpperArm";
		"RightLowerArm";
		"RightHand";
	}

	for _, partName in ipairs(parts) do
		local part = character:FindFirstChild(partName)
		if part then
			if part.Transparency ~= transparency then
				part.Transparency = transparency
			end
		end
	end
end

local function GetFireTarget()
	local targetPosition = mouse.Hit.Position
	local rayOrigin = Shared.rayOrigin.Position

	local rayDirection = (targetPosition - rayOrigin).Unit * 1000
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return result, rayOrigin, rayDirection, targetPosition
end

bindableEquip.Event:Connect(function(slot)
	print(`BindableEquip called with {slot}`)
	
	local weapon = slots[slot]
	if not weapon then
		equipped = false
		return
	end
	
	_G.GunEquipped = weapon
	
	if equipped then
		
	else
		print(`Equipping {weapon.Name}`)
		CurrentGunName = weapon.Name
		ViewModel = weapon.Path.ViewModel
		Shared.gun = ViewModel.Gun
		Shared.ViewModel = ViewModel
		equipped = true
	end
	
	Remotes.EquipWeapon:FireServer(weapon.Name, equipped)
end)

bindableAim.Event:Connect(function(yn)
	print(`BindableAim called {not aiming}`)
	if not _G.GunEquipped then return end
	aiming = yn
end)

bindableFire.Event:Connect(function()
	local result, _, _, targetPosition = GetFireTarget()
	Remotes.FireWeapon:FireServer(targetPosition)
end)

RunService.RenderStepped:Connect(function(dt)
	Shared.aiming = aiming
	if player.Character.Humanoid.Health <= 0 then
		equipped = false
	end
	
	local WeaponViewModels = game.Workspace.VisibleWeaponViewModels
	for _, v in WeaponViewModels:GetChildren() do
		if v.Name == player.Name then
			v.Parent = RS.HiddenWeaponViewModels
		end
	end
	
	for _, v in Tracers:GetChildren() do
		if v.Name == player.Name then
			v:Destroy()
		end
	end
	
	if equipped then
		SetArmsTransparency(player, 1)
		player.CameraMaxZoomDistance = 0.5
		player.CameraMinZoomDistance = 0.5
	else
		SetArmsTransparency(player, 0)
		player.CameraMinZoomDistance = defaultZoom.Min
		player.CameraMaxZoomDistance = defaultZoom.Max
	end
	
	if player.CameraMaxZoomDistance == 0.5 then
		uis.MouseIconEnabled = false
		local FPViewModel = Camera:FindFirstChild("ViewModel" .. CurrentGunName)
		if not FPViewModel then
			print("Creating FPS view")
			createFPVModel()
		else
			local rot = Camera.CFrame:ToObjectSpace(lastCameraCF)
			local X, Y = rot:ToOrientation()
			swayCF = swayCF:Lerp(CFrame.Angles(math.sin(X) * swayAmount, math.sin(Y) * swayAmount, 0), 0.1)
			lastCameraCF = Camera.CFrame
			
			local primaryPart = FPViewModel.PrimaryPart
			local aimPart = FPViewModel:FindFirstChild("AimPart")
			local rayOrigin = FPViewModel:FindFirstChild("rayOrigin")
			Shared.rayOrigin = rayOrigin
			Shared.fpvGun = FPViewModel:FindFirstChild("Gun")
			
			if aiming and aimPart and primaryPart then
				CameraController.Zoom(45, AimZoomTimeFirstPerson)
				local offset = aimPart.CFrame:ToObjectSpace(primaryPart.CFrame)
				aimCF = aimCF:Lerp(offset, AimTimeFirstPerson)
			else
				CameraController.Zoom(70, AimZoomTimeFirstPerson)
				aimCF = aimCF:Lerp(CFrame.new(), AimTimeFirstPerson)
			end
			
			Shared.recoilOffset = Shared.recoilOffset:Lerp(CFrame.identity, math.clamp(dt*12,0,1))
			Shared.cameraRecoilOffset = Shared.cameraRecoilOffset:Lerp(CFrame.identity, math.clamp(dt*12,0,1))

			FPViewModel:SetPrimaryPartCFrame(
				Camera.CFrame * swayCF * aimCF * Shared.recoilOffset
			)
			Camera.CFrame = Camera.CFrame * Shared.cameraRecoilOffset
			
			Remotes.AimReport:FireServer(Camera.CFrame)
		end
	else
		_G.GunEquipped = nil
		uis.MouseIconEnabled = true
		CameraController.Zoom(70, 0)
		if CurrentGunName then
			destroyFPViewModel()
		end
	end
end)

bindableReload.Event:Connect(function()
	ReloadWeapon:FireServer()
end)