-- LocalScript

-- This is a custom implementation to the game's UI. It is natively not going to scale well on devices as it was designed to be dynamic in size, so this script makes sure that it always looks good.

repeat task.wait() until game:IsLoaded() do end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function updateSize(window)
	if not window or not window:IsA("GuiObject") then return end
	local parentFrame = window.Parent
	if not parentFrame then return end

	local totalSize = 0
	local padding = window:FindFirstChildOfClass("UIPadding")
	local topPad, bottomPad = 0, 0
	if padding then
		topPad = padding.PaddingTop.Offset + (padding.PaddingTop.Scale * window.AbsoluteSize.Y)
		bottomPad = padding.PaddingBottom.Offset + (padding.PaddingBottom.Scale * window.AbsoluteSize.Y)
	end

	for _, child in ipairs(window:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			totalSize += child.AbsoluteSize.Y + 0.5
		end
	end

	totalSize += topPad + bottomPad
	window.Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset, 0, totalSize)
end

local function connectChildSignals(window)
	for _, child in ipairs(window:GetChildren()) do
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				updateSize(window)
			end)
			--child:GetPropertyChangedSignal("Visible"):Connect(function()
			--	updateSize(window)
			--end)
		end
	end
end

local uis = { player.PlayerGui:WaitForChild("WarningUI"):WaitForChild("Frame"):WaitForChild("Frame"), player.PlayerGui:WaitForChild("FinishedUI"):WaitForChild("Frame"):WaitForChild("Frame") }
for _, rootWindow in ipairs(uis) do
	updateSize(rootWindow)
	connectChildSignals(rootWindow)
	rootWindow.ChildAdded:Connect(function(child)
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				updateSize(rootWindow)
			end)
			child:GetPropertyChangedSignal("Visible"):Connect(function()
				updateSize(rootWindow)
			end)
		end
		updateSize(rootWindow)
	end)

	rootWindow.ChildRemoved:Connect(function()
		updateSize(rootWindow)
	end)

	rootWindow:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateSize(rootWindow)
	end)
end

