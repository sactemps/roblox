-- Script

-- [[
--    PlayerAdded.lua
--	  Handles player join & data validation
--    Demonstrates security implementations
--    
--    Made by sac_ie
--]]

-- This is a barebones version of what you would see on the server side. For reasons that shouldn't have to be mentioned, not everything is here!

-- KEEP IN MIND:
-- This game is CAPPED to one player. Therefore, a lot of code you may see here is structured to only work with ONE player. Don't be confused.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")

local CODES = {
    SUCCESS = ...;
    NOT_FOUND = ...;
    EXPIRED = ...;
    WAIT = ...;
}

local function onPlayerAdded(player)    
	player.CharacterAdded:Connect(function(char)
		char:Destroy()
	end)

	local remote = events:WaitForChild("SetPlayerProperties")
	remote:FireClient(player)
		
	local launchData = player:GetJoinData().LaunchData
			
	local sessionCode = nil
	local key = nil
	
	if RunService:IsStudio() then
		launchData = "eyJrZXkiOiAiVGVzdEtleSIsICJzZXNzaW9uX2NvZGUiOiAiVGVzdENvZGUifQ"
	end
	
	if not launchData then
		return player:Kick("Missing launch data. Did you use the correct link?")
	end	
		
	local sessionCode, key = nil, nil
	
    print("Converting from B64 to readable")
    local function from_base64(data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
    
    local decodedB64 = from_base64(launchData)
                        
    if decodedB64:sub(1,2) == '{"' then
        local success, data = pcall(HttpService.JSONDecode, HttpService, decodedB64)
        
        if not success then
            return player:Kick("Could not parse the launch data body. Did you use the correct link?")
        end
        
        -- Make sure that the server only receives session_code or key and nothing else
        local ALLOWED_KEYS = {"session_code", "key"}
        local function isKeyAllowed(key)
            for _, allowedKey in ipairs(ALLOWED_KEYS) do
                if allowedKey == key then
                    return true
                end
            end
            return false	
        end

        for k, v in pairs(data) do
            if not isKeyAllowed(k) then
                return player:Kick("Arbitrary data key received")
            end
        end

        sessionCode = data.session_code
        key = data.key
    else
        player:Kick("Invalid data")
    end
			
	if not sessionCode or not key then
		return player:Kick("You did not provide a " .. (not key and "key" or "session code") .. ".")
	end	

	local success, result = pcall(function()
		if RunService:IsStudio() then
			return {Kick = false, Msg = "Studio instance; bypass granted"}
		end
		
		local response = HttpService:RequestAsync({
            -- API CALL
		})
		
		if response.StatusCode == CODES.SUCCESS then
			return {Kick = false}
		elseif response.StatusCode == CODES.NOT_FOUND or response.StatusCode == CODES.EXPIRED then
			return {Kick = true, Msg = "The session credentials provided are invalid. Did you use the correct link?"}
		elseif response.StatusCode == CODES.WAIT then
			return {Kick = true, Msg = "You should not join the game yet."}
		else
			return {Kick = true, Msg = `Something went wrong`}
		end
	end)
	
    if not success then
        return player:Kick("An error occurred.")
    end

    if result.Kick then
        return player:Kick(result.Msg)
    end
		
	local replicatedSessionCode = ServerStorage:WaitForChild("SessionCode")
	replicatedSessionCode.Value = sessionCode
	
	local serverCanVerify = ServerStorage:WaitForChild("CanVerifyBool")
	serverCanVerify.Value = true
		
	-- Prompt player to confirm their account and therefore create a link with Nexus
	local playerConfirmationEvent = events:WaitForChild("PlayerVerificationConfirmation")
	playerConfirmationEvent:FireClient(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)