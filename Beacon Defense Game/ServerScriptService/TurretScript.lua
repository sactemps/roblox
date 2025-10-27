-- Script

-- [[
--    TurretScript.lua
--    Made by sac_ie
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceTurretEvent: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlaceTurret")

local baseTurret = game.Workspace:WaitForChild("Turret")
local baseplate = game.Workspace:WaitForChild("Baseplate")
local bpMinX = -(baseplate.Size.X / 2)
local bpMinZ = -(baseplate.Size.Z / 2)
local bpMaxX = (baseplate.Size.X / 2)
local bpMaxZ = (baseplate.Size.Z / 2)

PlaceTurretEvent.OnServerEvent:Connect(function(player, position)
	if typeof(position) ~= "Vector3" then return end
	local turret = baseTurret:Clone()
	turret.RadiusPart.Transparency = 1
	turret.Parent = game.Workspace.Turrets
	turret:MoveTo(Vector3.new(math.clamp(position.X, bpMinX, bpMaxX), 0, math.clamp(position.Z, bpMinZ, bpMaxZ)))
end)

local attackersFolder = game.Workspace:WaitForChild("Attackers")
local turretsFolder = game.Workspace:WaitForChild("Turrets")

local visuals = {}

for _, turret in turretsFolder:GetChildren() do
	local radiusInt = Instance.new("IntValue")
	radiusInt.Name = "Radius"
	radiusInt.Value = 20
	radiusInt.Parent = turret
	
	local radius = Instance.new("Part")
	radius.Name = "RadiusPart"
	radius.Orientation = Vector3.new(0, 90, 90)
	radius.Anchored = true
	radius.Shape = Enum.PartType.Cylinder
	radius.Size = Vector3.new(0.5, radiusInt.Value * 2, radiusInt.Value * 2)
	radius.Position = Vector3.new(turret.Position.X, 0, turret.Position.Z)
	radius.BrickColor = BrickColor.new("Really blue")
	
	local weld = Instance.new("WeldConstraint")
	weld.Parent = turret
	weld.Part0 = turret
	weld.Part1 = radius
	radius.Parent = turret
end

while true do
	print("Running turret(s)")

	for _, i in visuals do
		i:Destroy()
	end


	local turrets = turretsFolder:GetChildren()
	if #turrets > 0 then 
		for _, turret in turrets do
			task.spawn(function()
				local turretRadius = turret.Radius.Value
				local turret = turret.Turret -- children r currently grouped as a model
				local TURRET_DMG = turret:GetAttribute("Damage")
				if not TURRET_DMG then return end
				
				local attackerPositions = {}

				for _, attacker in attackersFolder:GetChildren() do
					if not attacker.Parent or attacker.Parent ~= game.Workspace.Attackers then continue end
					local distance = (attacker.HumanoidRootPart.Position - turret.Position).Magnitude
					table.insert(attackerPositions, {attacker, distance})
				end
				
				table.sort(attackerPositions, function(a, b) return a[2] < b[2] end)
				
				local attackersDamaged = 0
				for i, attackerInfo in attackerPositions do					
					local attacker = attackerInfo[1]
					local distance = attackerInfo[2]
					
					if not attacker:FindFirstChild("HumanoidRootPart") then continue end
					if not attacker:GetAttribute("Health") then continue end
					
					if distance <= turretRadius then
						local laser = Instance.new("Part")
						laser.Size = Vector3.new(0.5, 0.5, distance)	

						laser.CFrame = CFrame.lookAt((turret.Position + attacker.HumanoidRootPart.Position) / 2, attacker.HumanoidRootPart.Position)
						laser.Anchored = true
						laser.CanCollide = false
						laser.Material = Enum.Material.Neon
						laser.Parent = game.Workspace._Debug
						laser.BrickColor = BrickColor.new("Really red")
						
						table.insert(visuals, laser)
						
						attacker:SetAttribute("Health", attacker:GetAttribute("Health") - TURRET_DMG)
						attackersDamaged += 1
						
						task.wait(0.3)
						
						if attackersDamaged >= 2 then print("breaking (turret exhausted)"); break end
					end
				end	
			end)
		end
	end

	task.wait(1)	
end