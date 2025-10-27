-- ModuleScript

-- [[
--    Ban.lua
--	  A modular way to moderate players (and log it)
--    Demonstrates security implementations and modularity
--    
--    Made by sac_ie
--]]

-- This is a barebones version of what you would see on the server side. For reasons that shouldn't have to be mentioned, not everything is here!

local module = {}
local pending = {}

function module.Ban(plr: Player, displayReason: string, privateReason: string, description: string, duration: number)
	if pending[plr.UserId] then
		return
	end

	pending[plr.UserId] = true
	
	local function doBan()
		return pcall(function()
			game.Players:BanAsync({
				UserIds = {plr.UserId},
				ApplyToUniverse=true,
				Duration = duration,
				DisplayReason = displayReason,
				PrivateReason = privateReason,
				ExcludeAltAccounts = false
			})
		end)
	end
	
	local success, fail
	
	for i=1, 3 do
		success, fail = doBan()
		if success then break end
		task.wait(0.5 * i)
	end
	
    -- Logging operations are done here.

	pending[plr.UserId] = nil
end

return module