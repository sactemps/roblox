-- [[
--    InputHandler.client.lua
--	  Basic input handling for the gun system.
--    
--    Made by sac_ie
--]]

-- This was one of the first files I made for this project, and I didn't feel like reworking it into something "proper". Lacks modularity.

local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local mouse = player:GetMouse()

local bindableFire = RS.Bindable:WaitForChild("BindableFire")
local bindableReload = RS.Bindable:WaitForChild("BindableReload")
local bindableAim = RS.Bindable:WaitForChild("BindableAim")
local bindableEquip = RS.Bindable:WaitForChild("BindableEquip")

local function fire()
	bindableFire:Fire()
end

local function reload()
	bindableReload:Fire()
end

local function aim(yn)
	bindableAim:Fire(yn)
end

local function equipOne()
	bindableEquip:Fire(1)
end

local function equipTwo()
	bindableEquip:Fire(2)
end

uis.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.One then equipOne() end
	if input.KeyCode == Enum.KeyCode.Two then equipTwo() end
	
	if not _G.GunEquipped then return end
	
	if input.KeyCode == Enum.KeyCode.R then reload() end
end)



mouse.Button1Down:Connect(function()
	if not _G.GunEquipped then return end
	fire()
end)

local isButton2Down = false -- weird workaround because this is dumb
-- ^^ What I meant is, through testing, I found that spamming Button2 will give undesirable results if you trust the Roblox events (i.e. aiming mode being stuck on / becoming inverse)
mouse.Button2Down:Connect(function()
	if not _G.GunEquipped then return end
	if isButton2Down then return end
	isButton2Down = true
	aim(true)
end)
mouse.Button2Up:Connect(function()
	if not _G.GunEquipped then return end
	isButton2Down = false
	aim(false)
end)