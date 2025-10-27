game.ReplicatedStorage.UpdateMultiplierGUI.OnClientEvent:Connect(function(info)
	local player = game.Players.LocalPlayer
	local multiplierButton = player.PlayerGui.Multiplier.Frame.TextButton
	
	local price = info.price
	local default = info.default
	local timeRemaining = info.timeRemaining
	
	if default then
		multiplierButton.Text = "Activate Multiplier (" .. tostring(price) .. " coins)"
	else
		multiplierButton.Text = "Multiplier Active (" .. tostring(timeRemaining) .. " seconds)"
	end		
end)