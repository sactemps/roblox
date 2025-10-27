-- ModuleScript

-- [[
--    DoorModule.lua
--    Made by sac_ie
--]]

-- This took too much time :P

local DoorModule = {}

local TweenService = game:GetService("TweenService")
local doorTweenInfo = TweenInfo.new(0.3)

local doorTouchingPlayers = {}

local doorState = {}

function DoorModule.disableCollisions(person)
	for _, part in ipairs(person:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" or part.Name == "Torso" then
				part.CanCollide = true
			else
				part.CanCollide = false
			end
		end
	end
end

function DoorModule.openDoor(door)
	local originalCFrame = door.CFrame
	local hingeOffset = CFrame.new(door.Size.X / 2, 0, 0)
	local goalCFrame = originalCFrame * hingeOffset * CFrame.Angles(0, math.rad(90), 0) * hingeOffset:Inverse()
	local goal = { CFrame = goalCFrame }
	door.CanCollide = false
	return TweenService:Create(door, doorTweenInfo, goal)
end

function DoorModule.closeDoor(door, originalCFrame)
	local goal = { CFrame = originalCFrame }
	door.CanCollide = true
	return TweenService:Create(door, doorTweenInfo, goal)
end

function DoorModule.playAnimations(person, waveAnimName, idleAnimName)
	local waveAnim = person:WaitForChild("Animate"):FindFirstChild(waveAnimName):FindFirstChild("WaveAnim")
	local idleAnim = person:WaitForChild("Animate"):FindFirstChild(idleAnimName):FindFirstChild("Animation1")
	local humanoid = person:FindFirstChildOfClass("Humanoid")

	if humanoid and waveAnim and waveAnim:IsA("Animation") then
		local waveTrack = humanoid:LoadAnimation(waveAnim)
		local idleTrack = humanoid:LoadAnimation(idleAnim)
		waveTrack:Play()
		task.wait(1.5)
		waveTrack:Stop()
		idleTrack:Play()
		return idleTrack
	else
		warn("Either humanoid or wave animation is missing, or WaveAnim is not an Animation object")
	end
end

function DoorModule.onTouch(touchPart, door, person)
	local originalCFrame = door.CFrame

	if not doorTouchingPlayers[door] then
		doorTouchingPlayers[door] = {}
	end

	if doorState[door] == nil then
		doorState[door] = "closed"
	end

	touchPart.Touched:Connect(function(touched)
		local character = touched.Parent
		if not character then return end

		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player and not doorTouchingPlayers[door][player.UserId] then
				doorTouchingPlayers[door][player.UserId] = true
				print(player.Name .. " started touching the door.")

				if doorState[door] == "closed" or doorState[door] == "closing" then
					doorState[door] = "opening"
					local openDoorTween = DoorModule.openDoor(door)
					openDoorTween.Completed:Connect(function()
						doorState[door] = "open"
						print("Door is fully open")
					end)
					openDoorTween:Play()

					print(1)

					local idleTrack = DoorModule.playAnimations(person, "wave", "idle")
					print(2)
				end
			end
		end
	end)

	touchPart.TouchEnded:Connect(function(endedTouch)
		local character = endedTouch.Parent
		if not character then return end

		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player and doorTouchingPlayers[door][player.UserId] then
				doorTouchingPlayers[door][player.UserId] = nil
				print(player.Name .. " stopped touching the door.")
								
				if #doorTouchingPlayers[door] == 0 and doorState[door] == "open" then
					print("No players are touching the door, closing now.")
					doorState[door] = "closing"
					local closeDoorTween = DoorModule.closeDoor(door, originalCFrame)
					closeDoorTween.Completed:Connect(function()
						doorState[door] = "closed"
						print("Door is fully closed")
					end)
					closeDoorTween:Play()

				end
			end
		end
	end)
end

return DoorModule