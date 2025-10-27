-- ModuleScript

-- [[
--    ValidateRemote.lua
--	  A modular way to handle remote-specific exploiters
--    Demonstrates security implementations and modularity
--    
--    Made by sac_ie
--]]

-- ⚠️ This is a sanitized version of the anti-cheat module for portfolio purposes.
-- Most real thresholds, remote names, and other critical logic has been removed.
-- ... = redacted


local HttpService = game:GetService("HttpService")
local BanService = require(game.ServerScriptService.Moderation.Ban)

local module = {}

module.calls = {}
module.flags = {}
module.config = {}

module.q = {}
module.c = {}

local DISALLOWED
local ALLOWED
local OO_T

function module.eval(rem: RemoteEvent, plr: Player)
	local AllowRequest
	[...] = DISALLOWED
	table.insert(module.q, {[...]=rem,[...]=plr,[...]=AllowRequest})
	AllowRequest:Wait()
	return [...] == ALLOWED
end

function module.reg(rem: RemoteEvent, config: {})
	module.config[rem] = config
end

function _eval(rem, plr, res)
    local resetTime
    local flags
    local THRESHOLD
    local calls
    local pCalls

	if module.c[plr.UserId] then
		return -- This condition should ALWAYS be at the top. It will ONLY be true IF the player has been banned. This ensures we do not keep rebanning them with a lengthy queue of requests.
	end

	local function countFlags(t)
		local n = 0
		for _ in pairs(t) do
			n += 1
		end
		return n
	end
	
	local config = module.config[rem]
	if not config then
		return	
	end

	if not THRESHOLD then --?
		return false -- Something's wrong if this value isn't set!
	end

	if not flags then
		module.flags[plr.UserId] = {}
		flags = module.flags[plr.UserId]
	end
    
	if not calls then
		module.calls[rem] = {}
		calls = module.calls[rem]
	end
	
	if not pCalls then
		calls[plr.UserId] = {}
		pCalls = calls[plr.UserId]
	end
    
	local function ban(reason: string) [...] end
    
    local flagCount = countFlags(flags)

	if config.OnlyOnce then
		if flagCount >= OO_T then
			ban("You have been banned for cheating. If this is in error, contact us.")
		end
	elseif flagCount + 1 >= THRESHOLD then -- BEFORE letting the remote execute, make sure that this instance of execution will not exceed the rate limit
		ban("You have been banned for cheating. If this is in error, contact us.")	
	end

	local uuid = HttpService:GenerateGUID()

	local now = os.clock()
	table.insert(pCalls, { Time=now, Id=uuid })

	local filtered = {}

	for _, call in ipairs(pCalls) do
		local callTime = call.Time
		local id = call.Id
		if ((resetTime and now - callTime <= resetTime) or (config.OnlyOnce and #pCalls > 1)) and not flags[id] then
			res.Value = [...]

			if not flags[id] then
				flags[uuid] = now
			end
			
			flagCount += 1
		end 
	end
	if res.Value == ALLOWED then
		res.Value = DISALLOWED
	end
end

task.spawn(function()
	while task.wait() do
		local _task = table.remove(module.q, 1)
		if not _task then continue end
		local s, f = pcall(function()
			_eval(_task.R, _task.P, _task.I)
		end)
		if not s then
			warn(`{f}`)
		end
		module.q[1] = nil
	end
end)


return module
