-- LocalScript

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PlayerGui = player:WaitForChild("PlayerGui")
local loadingUI = PlayerGui:WaitForChild("LoadingUI")

loadingUI.Enabled = true

-- This script runs in the background while the server verifies session credentials.
-- Once the server wraps up, the player will either:
-- (A) Be kicked, with a reason
-- (B) Be prompted to confirm verification