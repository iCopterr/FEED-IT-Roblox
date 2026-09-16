local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.FarmConfig)
local FarmController = {}

function FarmController.Start()
	local player = Players.LocalPlayer
	local remote = game.ReplicatedStorage:WaitForChild("Farm")
	local track
	local lastExit = -math.huge
	local function exit()
		if Input:GetFocusedTextBox() then return end
		if player:GetAttribute("IsFarming") and os.clock() - lastExit >= Config.RequestCooldown then
			lastExit = os.clock()
			remote:FireServer("Exit")
		end
	end
	local function changed()
		if track then track:Stop(.1); track:Destroy(); track = nil end
		if not player:GetAttribute("IsFarming") or Config.RunAnimationId == "" then return end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end
		local animation = Instance.new("Animation")
		animation.AnimationId = Config.RunAnimationId
		local ok, result = pcall(function() return animator:LoadAnimation(animation) end)
		animation:Destroy()
		if ok then track = result; track.Looped = true; track.Priority = Enum.AnimationPriority.Action; track:Play(.1) end
	end
	player:GetAttributeChangedSignal("IsFarming"):Connect(changed)
	player.CharacterRemoving:Connect(function()
		if track then track:Stop(); track:Destroy(); track = nil end
	end)
	Input.InputBegan:Connect(function(input)
		if Input:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D
			or input.KeyCode == Enum.KeyCode.Space then exit() end
	end)
	Input.JumpRequest:Connect(exit)
	-- Touch/gamepad movement also exits, after releasing the approach input.
	local armed = false
	player:GetAttributeChangedSignal("IsFarming"):Connect(function() armed = false end)
	RunService.Heartbeat:Connect(function()
		if not player:GetAttribute("IsFarming") then return end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		if humanoid.MoveDirection.Magnitude < .05 then armed = true
		elseif armed then exit() end
	end)
	changed()
end

return FarmController
