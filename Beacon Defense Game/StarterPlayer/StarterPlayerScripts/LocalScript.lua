-- LocalScript

-- [[
--    LocalScript.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameOver")

remote.OnClientEvent:Connect(function()
	player.PlayerGui.GameOver.Enabled = true
end)