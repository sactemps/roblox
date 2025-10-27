-- Script

-- [[
--    Attackers.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local attackersFolder = game.Workspace:WaitForChild("Attackers")
local remote: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerDamageAttacker")

remote.OnServerEvent:Connect(function(player, attacker)
	if attacker and attacker:GetAttribute("Attacker") then
		local health = attacker:GetAttribute("Health")
		if not health or typeof(health) ~= "number" then return end
		attacker:SetAttribute("Health", health - 5)
	end
end)

attackersToDestroy = {}

task.spawn(function()
	while task.wait(1) do
		for _, info in ipairs(attackersToDestroy) do
			task.spawn(function()
				local attacker = info.Attacker
				local event = info.Event
				
				event:Disconnect()
				
				if not attacker:FindFirstChild("Humanoid") then
					return attacker:Destroy()
				end
				attacker.Humanoid.Health = 0
				attacker:BreakJoints()
				task.wait(1)
				if attacker.Parent then
					print("destroying")
					attacker:Destroy()
				end
			end)
		end
	end
end)

attackersFolder.ChildAdded:Connect(function(child)
	if not child:FindFirstChild("Humanoid") then return end
	if not child:GetAttribute("Attacker") then return end
	
	local event = nil
	local function onDamage(attr)
		if attr == "Health" then
			local health = child:GetAttribute("Health")
			child.BillboardGui.Health.Size = UDim2.new(health / child:GetAttribute("BASE_HEALTH"), 0, 0.5, 0)
			child.BillboardGui.Frame.HP.Text = health
 			if health <= 0 then								
				child.Parent = nil
				table.insert(attackersToDestroy, { Attacker = child, Event = event })
				return
			end
		end
	end
	
	event = child.AttributeChanged:Connect(onDamage)
	
	child.Changed:Connect(function(property)
		if property == "Parent" then
			event:Disconnect()
		end
	end)
end)