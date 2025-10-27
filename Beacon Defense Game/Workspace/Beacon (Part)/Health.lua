-- Script

-- [[
--    Health.lua
--    Made by sac_ie
--]]

local ServerStorage = game:GetService("ServerStorage")

local beacon = script.Parent
local health = beacon.Health

health.Changed:Connect(function(value)
	beacon.BillboardGui.TextLabel.Text = value
	if value <= 0 then
		ServerStorage.GameOver.Value = true
	end
end)