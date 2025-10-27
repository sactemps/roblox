repeat task.wait() until game.Loaded do end

local ValidateRemote = require(game.ServerScriptService.AntiCheat.ValidateRemote)
local configuration = require((game.ServerScriptService.AntiCheat.RemoteConfigurations.ModuleScript))

for remoteName, config in configuration do
	ValidateRemote.reg(game.ReplicatedStorage.Events:FindFirstChild(remoteName), config)
end