-- Script

-- [[
--    PlayerAdded.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local function setCollisionGroup(model)
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "Players"
			end
		end
	end

	player.CharacterAdded:Connect(function(character)
		setCollisionGroup(character)
	end)

	if player.Character then
		setCollisionGroup(player.Character)
	end
end)