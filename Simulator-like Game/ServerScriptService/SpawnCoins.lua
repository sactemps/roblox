-- Script

-- [[
--    SpawnCoins.lua
--    Made by sac_ie
--]]

local coins = {}

local function getRandomPositionInArea(basePart)
	local baseSize = basePart.Size
	local basePosition = basePart.Position

	local minX = basePosition.X - baseSize.X / 2
	local maxX = basePosition.X + baseSize.X / 2
	local minZ = basePosition.Z - baseSize.Z / 2
	local maxZ = basePosition.Z + baseSize.Z / 2

	local randomX = math.random(math.floor(minX), math.floor(maxX))
	local randomY = basePosition.Y
	local randomZ = math.random(math.floor(minZ), math.floor(maxZ))

	return Vector3.new(randomX, randomY, randomZ)
end

local function spawnPartInArea(referencePart)
	local newCoin = game.ReplicatedStorage.Coin:Clone()
	newCoin.Position = getRandomPositionInArea(referencePart)
	newCoin.LightPart.Position = Vector3.new(newCoin.Position.X, newCoin.Position.Y + 5, newCoin.Position.Z)
	newCoin.Anchored = true
	newCoin.Parent = workspace
	coins[newCoin] = true
end

local function countCoins()
	local count = 0
	for _, _ in pairs(coins) do
		count = count + 1
	end
	return count
end

local referencePart = game.ReplicatedStorage.CoinSpawnConstraint

while true do
	for coin in pairs(coins) do
		if not coin:IsDescendantOf(workspace) then
			coins[coin] = nil
		end
	end

	if countCoins() < 5000 then
		spawnPartInArea(referencePart)
	end

	task.wait(math.random(.1, .3))
end