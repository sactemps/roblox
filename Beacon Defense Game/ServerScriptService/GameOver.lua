-- Script

-- [[
--    GameOver.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameOver")

ServerStorage:WaitForChild("GameOver").Changed:Connect(function(value)
	if value then
		for _, instance in game.Workspace:GetChildren() do
			if instance:GetAttribute("Attacker") then
				instance:Destroy()
			end
		end
		remote:FireAllClients()
	end
end)