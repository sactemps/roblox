print("Core loaded")

local player = game.Players.LocalPlayer

local consoleProxPrompt = workspace.Zones.ControlCenter.ConsoleA:WaitForChild("Main").ProximityPrompt
local terminalUi = player.PlayerGui.UI.Terminal

local function addCommandBox(command: string)
	local terminalUi = player.PlayerGui.UI.Terminal
	if not terminalUi:FindFirstChild("Container") then return end
	
	local commandFrame = terminalUi.Container.CommandFrame.TemplateCommand:Clone()
	commandFrame.Name = "Command"
	commandFrame.Parent = terminalUi.Container.CommandFrame
	commandFrame.TextLabel.Text = command
	if string.find(commandFrame.TextLabel.Text, "\n") then
		commandFrame.AutomaticSize = Enum.AutomaticSize.XY
	end
	commandFrame.Visible = true
	return commandFrame
end

local inConsole = false
local terminalCleared = false
local terminalLoaded = false

terminalUi:GetPropertyChangedSignal("Enabled"):Connect(function()
	print(1)
	if terminalUi.Enabled then
		inConsole = true
	else
		inConsole = false
		for _, child in player.PlayerGui.UI:WaitForChild("Terminal").Container.CommandFrame:GetChildren() do
			if child:IsA("Frame") then
				if child.Name == "Command" then
					child:Destroy()
				end
			end
		end 
	end
end)

terminalUi.AncestryChanged:Connect(function(child, parent)
	if not child:IsDescendantOf(game) then
		terminalUi = player.PlayerGui.UI:WaitForChild("Terminal")
		terminalCleared = false
		inConsole = false
		terminalLoaded = false
	end
end)

consoleProxPrompt.Triggered:Connect(function()
	if inConsole then return end
	
    -- bunch of random stuff thats looks cool
	local bootMessages = {
		"[BOOT] Initializing core modules...",
		"[OK] Kernel loaded successfully (v5.12.48)",
		"[INFO] Scanning connected devices...",
		"[OK] USB Controller initialized (2 devices found)",
		"[OK] SATA Bus: 1 device mounted (/dev/sda)",
		"[MOUNT] /boot mounted successfully at /dev/sda1",
		"[INIT] Starting system services...",
		"[OK] Service: netlinkd ✔",
		"[OK] Service: secure-auth ✔",
		"[OK] Service: telemetry-daemon ✔",
		"[INFO] Establishing secure communication with gateway...",
		"[OK] Handshake complete (RSA-4096)",
		"[BOOT] Loading environment variables...",
		"[ENV] SYSTEM_MODE = PROD",
		"[ENV] ENABLE_ANALYTICS = TRUE",
		"[OK] All environment variables loaded",
		"[INFO] Checking for updates...",
		"[OK] System is up-to-date",
		"[INFO] Running pre-flight diagnostics...",
		"[PASS] Memory check: 16384MB OK",
		"[PASS] CPU check: 8 cores detected",
		"[PASS] GPU status: Online (NVIDIA RTX 5090)",
		"[PASS] Disk check: 512GB free of 1TB",
		"[BOOT] Launching user-space interface...",
		"[OK] UI core loaded (build #4D9A3F2)",
		"[INFO] Syncing time with NTP server...",
		"[OK] Time synchronized (UTC+0)",
		"[INFO] Verifying BIOS integrity...",
		"[PASS] BIOS checksum valid",
		"[INFO] Detecting network interfaces...",
		"[OK] Interface eth0 online (192.168.0.14)",
		"[OK] Interface wlan0 online (10.0.0.24)",
		"[INFO] Mounting additional partitions...",
		"[MOUNT] /data mounted at /dev/sdb1",
		"[MOUNT] /media mounted at /dev/sdc1",
		"[INIT] Initializing background services...",
		"[OK] Service: watchdog ✔",
		"[OK] Service: diskmonitor ✔",
		"[OK] Service: syslog ✔",
		"[INFO] Loading security modules...",
		"[OK] AppArmor loaded with 12 profiles",
		"[OK] SELinux in permissive mode",
		"[INFO] Verifying cryptographic modules...",
		"[PASS] OpenSSL 3.0.7 passed self-test",
		"[PASS] libcrypt 2.1 ready",
		"[INFO] Establishing VPN tunnel...",
		"[OK] VPN active (10.8.0.1)",
		"[INFO] Checking system entropy...",
		"[PASS] Entropy pool full (4086/4096)",
		"[INFO] Running boot-time hooks...",
		"[OK] Hook: cleanup-temp ✔",
		"[OK] Hook: preload-cache ✔",
		"[OK] Hook: update-log-index ✔",
		"[INFO] Boot script execution started...",
		"[OK] Executed: init-network.sh",
		"[OK] Executed: init-storage.sh",
		"[OK] Executed: start-daemons.sh",
		"[BOOT] Performing final checks...",
		"[PASS] All critical services online",
		"[PASS] No errors reported in last boot",
		"[READY] System boot complete. Welcome, Commander.", 
		"\n",
		"Press any key to continue."
	}
	
	local now = os.clock()
	local delay = 0.1
	local lastTime = now
	
	local bootMessageMap = {}
	for _, message in ipairs(bootMessages) do
		if message == "\n" then
			bootMessageMap[message] = lastTime + delay
			lastTime += delay
			continue
		end
		
		local increment
		if message:sub(1, 4) == "[OK]" or message:sub(1, 4) == "[INFO]" or message:sub(1, 5) == "[ENV]" then
			increment = 0.05
		elseif message:sub(1, 6) == "[BOOT]" or message:sub(1, 6) == "[PASS]" or message:sub(1, 7) == "[MOUNT]" then
			increment = math.random(5, 25) / 100
		elseif message:sub(1, 6) == "[INIT]" then
			increment = math.random(100, 150) / 100
		elseif message:sub(1, 7) == "[READY]" then
			increment = 1
		else
			increment = 0.1
		end
		
		lastTime += increment
		bootMessageMap[message] = lastTime
	end
	
	local RunService = game:GetService("RunService")
	local nextMessage = nil
	local messagesAdded = 0
	
	lastTime = nil
	
	local event = RunService.Heartbeat:Connect(function(dt)
		local hbTime = os.clock()
		
		local diff = nil		
		if lastTime ~= nil then
			diff = hbTime - lastTime
		else
			lastTime = hbTime
		end
				
		if not diff or diff <= 0.05 then
			return
		end
		
		lastTime = hbTime
		
		for message, time in bootMessageMap do
			if not terminalUi.Enabled then return end
			if not time then continue end
			
			if hbTime >= time then
				bootMessageMap[message] = nil
				nextMessage = message
				
				messagesAdded += 1
				
				local commandFrame = addCommandBox("")
				
				local str = ""
				
				task.spawn(function()
					if terminalUi.Parent ~= player.PlayerGui.UI then return end
					
					for i = 1, #message do
						str = str .. message:sub(i, i)
						if i % 4 == 0 then
							local textLabel = commandFrame:FindFirstChild("TextLabel")
							if not textLabel then return end
							commandFrame.TextLabel.Text = str
							task.wait()
						end
					end
					if commandFrame.TextLabel.Text ~= str then
						commandFrame.TextLabel.Text = str
					end
				end)
				
				break
			end
		end
	end)
		
	local terminalUi = player.PlayerGui.UI.Terminal

	terminalUi.Enabled = true
	
	repeat task.wait() until messagesAdded == #bootMessages do end
	print("Boot sequence finished")
	event:Disconnect()

	if not inConsole then return end

	terminalLoaded = true
	
	terminalUi.Container.BootingSystemFrame.Visible = false
end)

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		if terminalLoaded and terminalUi.Enabled then
			if not terminalCleared then
				terminalCleared = true
				if not terminalUi:FindFirstChild("Container") then return end
				
				for _, child in terminalUi.Container.CommandFrame:GetChildren() do
					if child.Name == "Command" and child:IsA("Frame") then
						child:Destroy()
					end
				end
				local welcomeCommand = addCommandBox([[
Welcome to EchoOS 1.0 (x86_64)

 * System Status:  All systems operational

Last login: ??? from ???
]])
				welcomeCommand.AutomaticSize = Enum.AutomaticSize.XY			
				terminalUi.Container.CommandFrame.RunCommand.Visible = true
				return
			end
		
			if input.KeyCode == Enum.KeyCode.Return and terminalUi.Container.CommandFrame.RunCommand.TextBox.Text == "" then			
				addCommandBox("")
			elseif input.KeyCode ~= Enum.KeyCode.Unknown then
				if input.KeyCode == Enum.KeyCode.T then
					task.wait()
					terminalUi.Container.CommandFrame.RunCommand.TextBox:CaptureFocus()
					return
				end
			end
		end
	end
end)

local terminalTextBox = terminalUi.Container.CommandFrame.RunCommand.TextBox

local function processCommand(command)
	print(command)
	
	local commands = {
		["ping"] = { Response = "System pinged", Description = "Ping the system" },
		["status"] = { Response = "System status: online", Description = "View system status" },
		["logs"] = { Response = "ERR", Description = "View system logs" },
		["help"] = { Response = "", Description ="View commands" },
		["sudo rm -rf /"] = { Response = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nERR" }
	}
	
	local helpCommandStr = ""
	
	for commandName, info in commands do
		if not info.Description then continue end
		helpCommandStr = helpCommandStr .. commandName .. ": " .. info.Description .. "\n"
	end
	helpCommandStr = string.sub(helpCommandStr, 1, -3)
	
	commands["help"] = { Response = helpCommandStr, Description = "View commands" }
	
	local commandRan = commands[command]

	if not commandRan then
		addCommandBox("Unknown command. Enter help to view all commands.")
	else
		addCommandBox(commandRan.Response)
	end
end

terminalTextBox.FocusLost:Connect(function(enterPressed, _)
	if enterPressed then
		if terminalTextBox.Text ~= "" then
			addCommandBox("> " .. terminalTextBox.Text)
			processCommand(terminalTextBox.Text)
			
			task.wait()
			terminalTextBox:CaptureFocus()
			terminalTextBox.Text = ""
		end
	end
end)