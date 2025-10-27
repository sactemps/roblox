-- LocalScript

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local warningUI = PlayerGui:WaitForChild("WarningUI")
local loadingUI = PlayerGui:WaitForChild("LoadingUI")

local finishedUI = PlayerGui:WaitForChild("FinishedUI")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("VerificationSuccess")

remote.OnClientEvent:Connect(function(result, msg)
	print("Server message")
	
	warningUI.Enabled = false
	loadingUI.Enabled = false
	
	if result == "success" then
		finishedUI.Frame.Frame.Title.Text = "Account Verified"
		finishedUI.Frame.Frame.Description.Text = "You can now return to Nexus."
	else
		finishedUI.Frame.Frame.Title.Text = "Account Not Verified"
		finishedUI.Frame.Frame.Description.Text = "We couldn't verify you."
		if msg then
			finishedUI.Frame.Frame.SubTextLabel.Text = tostring(msg)
			finishedUI.Frame.Frame.SubTextLabel.Visible = true
		end
	end
	
	finishedUI.Enabled = true
end)