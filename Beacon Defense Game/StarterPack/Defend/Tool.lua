-- LocalScript

-- [[
--    Tool.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerDamageAttacker")

local player = Players.LocalPlayer

local tool = script.Parent
local clickListener

local function onInput(input, gpe)
	if gpe then return end
	
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	
	local target = player:GetMouse().Target
		
	if target and target.Parent and target.Parent:GetAttribute("Attacker") then		
		remote:FireServer(target.Parent)
	end
	
end

local function onEquipped(_)
	if clickListener then clickListener:Disconnect() end
	clickListener = UserInputService.InputBegan:Connect(onInput)
end

local function onUnequipped(_)
	if clickListener then clickListener:Disconnect() end
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)