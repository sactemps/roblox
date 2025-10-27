-- Script

-- [[
--    DataSaving.lua
--    Made by sac_ie
--]]

local DataStoreService = game:GetService("DataStoreService")
local datastore = DataStoreService:GetDataStore("Coins")

local function fetchData(player)
	local playerData
	local success, errorMessage = pcall(function()
		playerData = datastore:GetAsync(tostring(player.UserId))
	end)

	if success then
		if not playerData then
			return {coins = 0}
		end
		return playerData
	else
		warn("Error fetching data for player " .. player.Name .. ": " .. errorMessage)
		player:Kick("An error occurred while fetching data: " .. errorMessage)
	end
end

local function setData(player)
	local coins = player.leaderstats:FindFirstChild("Coins")
	local multiplier = player.leaderstats:FindFirstChild("Multiplier")


	local data = {
		coins = coins.Value or 0
	}

	local success, errorMessage = pcall(function()
		datastore:SetAsync(tostring(player.UserId), data)
	end)

	if success then
		print("Data for " .. player.Name .. " has been saved.")
	else
		warn("Error saving data for " .. player.Name .. ": " .. errorMessage)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	print("Player joined: " .. player.Name)
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local multiplier = Instance.new("IntValue")
	multiplier.Name = "Multiplier"
	multiplier.Parent = leaderstats

	local playerData = fetchData(player)

	coins.Value = playerData.coins
	multiplier.Value = 1

	local multiplierGui = player.PlayerGui:WaitForChild("Multiplier")
	multiplierGui.Frame.AnchorPoint = Vector2.new(0.5, 0)
	multiplierGui.Frame.Position = UDim2.new(0.5, 0, 0, 0)

	multiplierGui.Frame.TextButton.Text = "Activate Multiplier (" .. 50 .. " coins)"
	multiplierGui.Enabled = true
end)

game.Players.PlayerRemoving:Connect(function(player)
	setData(player)
end)