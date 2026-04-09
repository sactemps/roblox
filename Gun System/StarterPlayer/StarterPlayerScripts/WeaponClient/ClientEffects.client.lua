local AimZoomTimeFirstPerson = 0.2
local recoilAmount = 1
local recoilAmountAiming = 0.75
local recoilTime = 0.025
local recoilReturnAmount = -0.75

local uis = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = require(script.Parent.Shared)
local GunAssets = RS:WaitForChild("GunAssets")
local Casing = GunAssets:WaitForChild("BulletCasing")
local Tracers = game.Workspace:WaitForChild("Tracers")
local Shared = require(script.Parent.Shared)

local player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")
local mouse = player:GetMouse()

local TS = game:GetService("TweenService")
local aiming = Shared.aiming
local equipped = Shared.equipped
local recoilOffset = Shared.recoilOffset

local bindableFire = RS.Bindable:WaitForChild("BindableFire")
local bindableReload = RS.Bindable:WaitForChild("BindableReload")
local bindableAim = RS.Bindable:WaitForChild("BindableAim")
local bindableEquip = RS.Bindable:WaitForChild("BindableEquip")

local defaultZoom = {
	Min = player.CameraMinZoomDistance,
	Max = player.CameraMaxZoomDistance
}

_G.MatchArmsToPlayer = function(viewModel, player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local skinColor = humanoid:GetAppliedDescription().HeadColor
	local shirt = character:FindFirstChild("Shirt")
	local ViewModelShirt = viewModel:FindFirstChild("Shirt")

	if viewModel:FindFirstChild("Right Arm") then
		viewModel["Right Arm"].Color = skinColor
	end

	if viewModel:FindFirstChild("Left Arm") then
		viewModel["Left Arm"].Color = skinColor
	end

	if shirt and ViewModelShirt then
		ViewModelShirt.ShirtTemplate = shirt.ShirtTemplate
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

local function BulletCasing(gun)
	local emitter = gun:FindFirstChild("BC_Emitter")
	if not emitter then return end
	
	local casing = Casing:Clone()
	
	local part = Casing:FindFirstChild("Casing")
	if not part then
		casing:Destroy()
		return
	end
	
	casing.Parent = game.Workspace
	
	part.Position = emitter.WorldPosition
	
	part.AssemblyLinearVelocity =
		emitter.WorldCFrame.RightVector * 8
		+ Vector3.new(0, 4, 0)

	part.AssemblyAngularVelocity = Vector3.new(
		math.random(-15, 15),
		math.random(-15, 15),
		math.random(-15, 15)
	)
	
	game.Debris:AddItem(casing, 3)
end

local function recoil()
	local strength = Shared.aiming and 0.5 or 1
	Shared.recoilOffset *= CFrame.new(0,0,-0.1*strength) * CFrame.Angles(math.rad(-2*strength),0,0)
	Shared.cameraRecoilOffset *= CFrame.Angles(math.rad(1.5*strength), math.rad(math.random(-0.5,0.5)*strength), 0)
end

bindableFire.Event:Connect(function()
	if not Shared.rayOrigin then return end
	
	local result, rayOrigin, rayDirection, targetPosition = GetFireTarget()

	local function BulletTracer(hitPosition)
		local rayOrigin = Shared.rayOrigin
		local att0 = rayOrigin.Attachment0:Clone()
		local att1 = rayOrigin.Attachment1:Clone()
		local beam = rayOrigin.Beam:Clone()
		
		local dist = (hitPosition - rayOrigin.Position).Magnitude
		
		beam = beam:Clone()
		beam.Parent = game.Workspace
		beam.Enabled = true

		att1.Parent = game.Workspace
		att0.Parent = game.Workspace

		att1.WorldPosition = hitPosition
		att0.WorldPosition = rayOrigin.Position
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.CurveSize1 = 0
		beam.TextureLength = dist / 3
		task.wait(.05)

		att0:Destroy()
		att1:Destroy()
		beam:Destroy()
	end

	if result then
		BulletTracer(result.Position) -- Raycast success; hit something
	else
		local missPosition = rayOrigin + rayDirection * 300
		BulletTracer(missPosition) -- Raycast failed; hit void or something
	end

	recoil()
	BulletCasing(Shared.fpvGun)
end)

bindableReload.Event:Connect(function()
	
end)

bindableEquip.Event:Connect(function(slot)	
end)