-- Script

-- [[
--    Loop.lua
--    Made by sac_ie
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PathfindingService = game:GetService("PathfindingService")

local intermission = false
local function doIntermission(value: boolean)
	if typeof(value) ~= "boolean" then return warn("Incorrect type \"" .. typeof(value) .. "\"") end
	for _, player in Players:GetPlayers() do
		player.PlayerGui.Intermission.Enabled = value
	end
end

local wave = 1

local beacon = game.Workspace:WaitForChild("Beacon")

local bursts = {
	[1] = 2,
	[2] = 3,
	[3] = 4,
	[4] = 5,
	[5] = 6,
	[6] = 7,
	[7] = 8,
	[8] = 9,
	[9] = 10,
	[10] = 11
}

local spawns = {
	[1] = 4,
	[2] = 5,
	[3] = 6,
	[4] = 7,
	[5] = 8,
	[6] = 9,
	[7] = 10,
	[8] = 11,
	[9] = 12,
	[10] = 13
}

speeds = {
	[1] = 4,
	[2] = 4,
	[3] = 4,
	[4] = 6,
	[5] = 6,
	[6] = 12
}

task.spawn(function()	
	while true do
		local _bursts = bursts[wave] or 11
		for i = 1, bursts[wave] do
			local spawnLocations = game.Workspace.AttackerSpawns:GetChildren()
			local spawnLocation = spawnLocations[math.random(1, #spawnLocations)]
			spawnLocation = spawnLocation.Position
			local _spawns = spawns[wave] or 15
			for i = 1, _spawns do
				task.spawn(function()
					local _, errorMessage = pcall(function()
						if intermission then return end
						if ServerStorage.GameOver.Value then return end
						
						local rig = game.Workspace._Attacker:Clone()
						rig.Name = ""
						rig.Humanoid.WalkSpeed = speeds[wave]
						rig.HumanoidRootPart.Position = spawnLocation

						local humanoid = rig.Humanoid

						local path = PathfindingService:CreatePath()

						local DESTINATION = game.Workspace.Beacon.Position

						local waypoints
						local nextWaypointIndex
						local reachedConnection
						local blockedConnection

						local function followPath(destination)
							local success, errorMessage = pcall(function()
								path:ComputeAsync(spawnLocation, DESTINATION)
							end)

							if success and path.Status == Enum.PathStatus.Success then
								rig.Parent = game.Workspace.Attackers

								waypoints = path:GetWaypoints()

								blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
									if blockedWaypointIndex >= nextWaypointIndex then
										blockedConnection:Disconnect()

										followPath(DESTINATION)
									end
								end)

								if not reachedConnection then
									reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
										if reached and nextWaypointIndex < #waypoints then
											nextWaypointIndex += 1
											humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
										else
											reachedConnection:Disconnect()
											blockedConnection:Disconnect()
										end
									end)
								end

								nextWaypointIndex = 2
								humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
							else
								warn("Path not compiled!", errorMessage)
								rig:Destroy()
							end
						end

						followPath(DESTINATION)
					end)
					if errorMessage then
						warn("Error in rig pathfinding: " .. errorMessage .. "\nat " .. script:GetFullName())
					end
				end)

				task.wait(0.3)
			end
			task.wait(1)
		end
		
		repeat task.wait() until #game.Workspace.Attackers:GetChildren() == 0 do end
		

		print("New wave starting soon (intermission)")

		doIntermission(true)

		task.wait(3)

		doIntermission(false)

		wave += 1
		print("Wave begun: " .. wave)
	end
end)