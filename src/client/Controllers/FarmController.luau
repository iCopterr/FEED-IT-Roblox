local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
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
	-- JumpRequest covers keyboard, touch and gamepad jump controls.
	Input.JumpRequest:Connect(exit)
	changed()
end

return FarmController
