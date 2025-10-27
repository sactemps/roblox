local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local defaultCamMaxZoom = player.CameraMaxZoomDistance

local function hasProperty(object, propertyName)
	local success, _ = pcall(function()
		object[propertyName] = object[propertyName]
	end)
	return success
end

local function setPlayerVisibility(character, visibility, exclude)
	local _V = {[true]=0,[false]=1}
	for _, p in character:GetChildren() do
		if not p:IsA("BasePart") or not hasProperty(p, "Transparency") or p == character.HumanoidRootPart then continue end
		local _S = false
		if exclude then
			for _, e in exclude do
				if p == e then
					_S = true
				end
			end
		end
		if not _S then
			p.Transparency = _V[visibility]
		end
	end
end

local function setArmVisiblityInFirstPerson(character, visibility)
	local _V = {[true]=0,[false]=1}
	
	local function setLoc(obj)
		obj.LocalTransparencyModifier = _V[visibility]
	end
	
	for _, p in character:GetChildren() do
		if p:IsA("Model") then
			if p.Name == "Arms" then
				for _, a in p:GetChildren() do
					if a:IsA("BasePart") then
						setLoc(a)
					elseif a:IsA("Model")then
						for _, b in a:GetChildren() do
							if b:IsA("BasePart") then
								setLoc(b)
							elseif b:IsA("Folder") then
								print(b.Name)
								for _, c in b:GetChildren() do
									setLoc(c)
								end
							end
						end
					end
				end
			end	-- if then else if then else if then else if then else if then else if then else if then else if then else if then else if then else if then else if then else if then else
		end
	end
end

local equipped = false
local event = nil
local parts = {}

script.Parent.Equipped:Connect(function(mouse)
	equipped = true
	
	player.CameraMaxZoomDistance = 0
	
	task.wait() -- Allow camera zoom to take effect
	
	local part = Instance.new("Part")
	table.insert(parts, part)
	
	local cf
	cf = game.Workspace.Camera.CFrame
	part.Name = "_SawClamp"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.5, 0.5, 2)	
	part.Parent = game.Workspace._C
	part.CFrame = cf
	
	setPlayerVisibility(player.Character, false, {
		player.Character.LeftUpperArm, player.Character.LeftLowerArm, player.Character.LeftHand,
		player.Character.RightHand, player.Character.RightLowerArm, player.Character.RightUpperArm
	})
	
	local armRig = game.Workspace.Arms
	armRig.Parent = player.Character
	
	local modLeftArm = armRig.LeftArm
	local leftArm = modLeftArm.LeftArm
	local leftArmEnd = leftArm.LeftArmEnd
	local leftHand = leftArm.LeftHand
	
	local modRightArm = armRig.RightArm
	local rightArm = modRightArm.RightArm
	local rightArmEnd = rightArm.RightArmEnd
	local rightHand = rightArm.RightHand
	
	local circLeftHandBlock = armRig["Circular Saw"].HandPoints.LeftHand
	local circRightHandBlock = armRig["Circular Saw"].HandPoints.RightHand
		
	event = RunService.RenderStepped:Connect(function(_)		
		setArmVisiblityInFirstPerson(player.Character, true)
		
		if not equipped then
			if event then
				event:Disconnect()
			end
			return
		end
		
		cf = game.Workspace.CurrentCamera:GetRenderCFrame():ToWorldSpace(CFrame.new(0, -0.5, -1.5)) * CFrame.Angles(math.rad(90), 0, 0)
		armRig:PivotTo(cf)
		
		local blocks = {
			[modLeftArm] = circLeftHandBlock,
			[modRightArm] = circRightHandBlock
		}
		
		local function setArm(armModel, arm, armEnd)
			local circBlock = blocks[armModel]
			circBlock.Orientation = armEnd.Orientation

			local dist = armEnd.Position - circBlock.Position
			
			local camUp = game.Workspace.CurrentCamera.CFrame.UpVector
			local resultCf = CFrame.lookAt(armEnd.Position, circBlock.Position, camUp) * CFrame.Angles(math.rad(90), 0, 0)
			armModel.PrimaryPart.CFrame = resultCf
			arm.Size = Vector3.new(0.5, dist.Magnitude, 0.5)
			arm.Position = (armEnd.Position + circBlock.Position) / 2
		end
		
		setArm(modRightArm, rightArm, rightArmEnd)
		setArm(modLeftArm, leftArm, leftArmEnd)
	end)
end)

script.Parent.Unequipped:Connect(function(mouse)
	equipped = false
	
	player.Character.Arms.Parent = game.Workspace
	
	for _, p in ipairs(parts) do
		p:Destroy()
	end
	
	player.CameraMaxZoomDistance = defaultCamMaxZoom
	setPlayerVisibility(player.Character, true, {})
	setArmVisiblityInFirstPerson(player.Character, false)
end)