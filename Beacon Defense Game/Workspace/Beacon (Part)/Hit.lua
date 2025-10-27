-- Script

-- [[
--    Hit.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")

local beacon = script.Parent
local health = beacon.HealthInt

beacon.Touched:Connect(function(otherPart)
	if otherPart.Parent == nil then return end
	if Players:GetPlayerFromCharacter(otherPart.Parent) then return end
	if not otherPart.Parent:GetAttribute("Attacker") then return end
	
	local damage = 10
	health.Value -= damage
	
	otherPart.Parent:Destroy()
	
	print("Beacon attacked for " .. damage .. " damage!")
end)