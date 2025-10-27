-- Script

-- [[
--    VerificationHandler.lua
--	  Handles player verification and validation
--    Demonstrates anti-cheat integration and API request structure
--    
--    Made by sac_ie
--]]

-- This is a barebones version of what you would see on the server side. For reasons that shouldn't have to be mentioned, not everything is here!

-- KEEP IN MIND:
-- This game is CAPPED to one player. Therefore, a lot of code you may see here is structured to only work with ONE player. Don't be confused.

local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local events = ReplicatedStorage:WaitForChild("Events")
local remote = events:WaitForChild("PlayerProceeded")

local ValidateRemote = require(game.ServerScriptService.AntiCheat.ValidateRemote)

remote.OnServerEvent:Connect(function(player)
	if not ValidateRemote.eval(remote, player) then
		return warn(`Client {player.UserId} denied!`)
	end
		
	local success, errorMessage = pcall(function()
		local canVerify = ServerStorage:WaitForChild("CanVerifyBool")
		if not canVerify.Value then return end

		local sessionCodeObj = ServerStorage:WaitForChild("SessionCode")
		if not sessionCodeObj.Value then return end
		local sessionCode = sessionCodeObj.Value

		print("-- CALLING THE API --")

		local success, result = pcall(function()
			if RunService:IsStudio() then
				return {Body = "Studio instance; bypass granted", StatusCode = 204, StatusText = nil}
			end

			return HttpService:RequestAsync({
				-- API CALL
			})
		end
		)
		
		if success then
			local enc = {}
			if result.Body or result.Body ~= "" then
				local suc, res = pcall(function() return HttpService:JSONDecode(result.Body) end)
				enc = (suc and res) or {}
			end
			events:WaitForChild("VerificationSuccess"):FireClient(player, (result.StatusCode == 204 and "success") or "failure", (result.StatusCode ~= 204 and `({enc.code}) {enc.message}`) or nil)
		else
			player:Kick("An error occurred while communicating with Nexus.")
		end
	end)
	if not success then
		player:Kick("Something went wrong on the server. Please try rejoining. A log has been sent to the developers.")
		-- LOG W/ MORE INFO IS SENT
	end
end)