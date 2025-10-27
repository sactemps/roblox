-- Script

-- [[
--    UpgradeMultiplier.lua
--    Made by sac_ie
--]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local datastore = DataStoreService:GetDataStore("Coins")

local multiplierPrice = 50
local multiplierTime = 10

local function fetchData(player)
	local playerData

	local success, errorMessage = pcall(function()
		playerData = datastore:GetAsync(tostring(player.UserId))
	end)

	if success then
		if not playerData then
			return {}
		end
		return playerData
	else
		warn("Error fetching data for player" .. player.Name .. ": " .. errorMessage)
		player:Kick("An error occurred while fetching data: " .. errorMessage)
	end
end

game.ReplicatedStorage.UpgradeMultiplier.OnServerEvent:Connect(function(player)
	local playerData = fetchData(player)
	print(playerData)

	local multiplier = player.leaderstats.Multiplier.Value
	local coins = player.leaderstats.Coins.Value

	if multiplier >= 2 then multiplier = 2 return end

	if coins >= multiplierPrice then
		local newMultiplier = 2
		
		local newCoins = coins - multiplierPrice
		player.leaderstats.Coins.Value = newCoins
		
		player.leaderstats.Multiplier.Value = newMultiplier
		
		for i=0, multiplierTime do
			print(i)
			if i == multiplierTime then
				player.leaderstats.Multiplier.Value = 1
				game.ReplicatedStorage.UpdateMultiplierGUI:FireClient(player, { price = multiplierPrice, default = true })
				return end
			
			local timeRemaining = multiplierTime - i
			game.ReplicatedStorage.UpdateMultiplierGUI:FireClient(player, { timeRemaining = timeRemaining })
			task.wait(1)
		end
	else
		warn("You cannot afford this! It costs: " .. multiplierPrice .. " coins.")
	end
end)