local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.FarmConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local CarryService = require(script.Parent.CarryService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local MerchantConfig = require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local FarmService = {}
local sessions, blocked, lastRequest, connections = {}, {}, {}, {}
local remote
local tokenRemote
local rng=Random.new()
local started = false

local function saveTokenDrop(player,data)
	task.spawn(function()
		while player.Parent==Players and DataService.GetData(player)==data do
			local ok,saved,reason=pcall(DataService.Save,player)
			if ok and saved then return end
			warn("[FarmService] Token save pending:",reason or saved)
			task.wait(MerchantConfig.SaveRetrySeconds)
		end
	end)
end

local function characterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return character, humanoid, root
end

local function station(player)
	local plot = PlotService.GetPlot(player)
	local farm = plot and plot:FindFirstChild("Farm")
	local work = farm and farm:FindFirstChild("WorkPoint")
	local exit = farm and farm:FindFirstChild("ExitPoint")
	if not work or not work:IsA("BasePart") or not exit or not exit:IsA("BasePart") then return nil end
	return farm, work, exit
end

local function standingAt(point, humanoid, root)
	local leg = humanoid.Parent:FindFirstChild("Left Leg")
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 and leg then height += leg.Size.Y end
	return point.CFrame + Vector3.new(0, height, 0)
end

function FarmService.GetRate(player)
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return 0 end
	-- Retired higher-level saves use the new cap without erasing saved progress.
	local level = math.min(data.FarmLevel, #Config.FoodPerSecond)
	local rate = (Config.FoodPerSecond[level] or 0) * data.FarmPower
	return if rate == rate and rate < math.huge then rate else 0
end

function FarmService.IsFarming(player)
	return sessions[player] ~= nil
end

function FarmService.Exit(player, moveOutside)
	local state = sessions[player]
	if not state then return false end
	sessions[player] = nil
	blocked[player] = true
	player:SetAttribute("IsFarming", false)
	state.Died:Disconnect()
	if state.Root.Parent then
		if moveOutside and player.Character == state.Character and state.Humanoid.Health > 0 and state.Exit:IsDescendantOf(workspace) then
			state.Root.CFrame = standingAt(state.Exit, state.Humanoid, state.Root)
		end
		state.Root.Anchored = state.Anchored
		state.Root.AssemblyLinearVelocity = Vector3.zero
		state.Root.AssemblyAngularVelocity = Vector3.zero
	end
	if state.Humanoid.Parent then state.Humanoid.AutoRotate = state.AutoRotate end
	return true
end

function FarmService.Enter(player)
	if sessions[player] then return false, "AlreadyFarming" end
	if blocked[player] then return false, "MoveAwayFirst" end
	local data = DataService.GetData(player)
	local character, humanoid, root = characterParts(player)
	local farm, work, exit = station(player)
	if not data or not Schema.Validate(data) then return false, "Loading" end
	if not character or not farm or root.Anchored or humanoid.Sit then return false, "Unavailable" end
	if (root.Position - work.Position).Magnitude > Config.EnterRadius then return false, "TooFar" end
	-- Held pets return to inventory; farming never changes pet identity/placement.
	CarryService.Unequip(player)
	local state = {Character=character, Humanoid=humanoid, Root=root, Farm=farm, Work=work, Exit=exit,
		Anchored=root.Anchored, AutoRotate=humanoid.AutoRotate, NextTick=os.clock()+Config.TickSeconds,
		NextTokenRoll=os.clock()+MerchantConfig.FarmDropInterval}
	sessions[player] = state
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid.AutoRotate = false
	root.CFrame = standingAt(work, humanoid, root)
	state.Target = root.CFrame
	state.Died = humanoid.Died:Connect(function() FarmService.Exit(player, false) end)
	player:SetAttribute("IsFarming", true)
	return true
end

-- Only elapsed server time can pay Food. Repeated calls cannot advance the clock.
function FarmService.Step(player)
	local state = sessions[player]
	local character, humanoid, root = characterParts(player)
	local farm, work = station(player)
	if not state then
		if not character or not work then return 0 end
		local distance = (root.Position - work.Position).Magnitude
		if blocked[player] then
			if distance > Config.RearmRadius then blocked[player] = nil end
		elseif distance <= Config.EnterRadius then
			FarmService.Enter(player)
		end
		return 0
	end
	local data = DataService.GetData(player)
	if character ~= state.Character or farm ~= state.Farm or work ~= state.Work or not data
		or not Schema.Validate(data) or not root.Anchored
		or (root.Position - state.Target.Position).Magnitude > Config.MaxWorkDistance then
		FarmService.Exit(player, false)
		return 0
	end
	local now = os.clock()
	if now < state.NextTick then return 0 end
	-- No offline income or catch-up bursts after a server stall.
	state.NextTick = now + Config.TickSeconds
	local amount = FarmService.GetRate(player) * Config.TickSeconds
	local nextFood = data.Food + amount
	if amount <= 0 or nextFood ~= nextFood or nextFood == math.huge then return 0 end
	data.Food = nextFood
	if remote then remote:FireClient(player, {Food=nextFood, FoodAt=now}) end
	if now>=state.NextTokenRoll then
		state.NextTokenRoll=now+MerchantConfig.FarmDropInterval
		local roll=if state.TestTokenRandom then state.TestTokenRandom() else rng:NextNumber()
		state.TestTokenRandom=nil
		if roll<MerchantConfig.FarmDropChance and data.Tokens<MerchantConfig.TokenCap then
			local awarded=math.min(MerchantConfig.FarmDropAmount,MerchantConfig.TokenCap-data.Tokens)
			data.Tokens+=awarded
			if tokenRemote then tokenRemote:FireClient(player,{Amount=awarded,Tokens=data.Tokens}) end
			saveTokenDrop(player,data)
		end
	end
	return amount
end

function FarmService.SetTestTokenRoll(player,random)
	assert(game:GetService("RunService"):IsStudio() and game:GetService("StudioTestService"):GetTestArgs()=="MerchantVerification"
		and require(script.Parent.Parent.Data.DataStoreAdapter).IsMemory(),"Test-only token RNG")
	local state=assert(sessions[player],"Player must be farming")
	state.TestTokenRandom=random;state.NextTokenRoll=0
end

function FarmService.HandleRequest(player, action)
	if action ~= "Exit" then return false end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < Config.RequestCooldown then return false end
	lastRequest[player] = now
	return FarmService.Exit(player, true)
end

function FarmService.Start()
	assert(not started, "FarmService already started")
	started = true
	remote = Instance.new("RemoteEvent")
	remote.Name = "Farm"
	remote.Parent = game.ReplicatedStorage
	remote.OnServerEvent:Connect(FarmService.HandleRequest)
	tokenRemote=Instance.new("RemoteEvent");tokenRemote.Name="FarmTokenDrop";tokenRemote.Parent=game.ReplicatedStorage
	local function watch(player)
		player:SetAttribute("IsFarming", false)
		connections[player] = player.CharacterRemoving:Connect(function() FarmService.Exit(player, false) end)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player)
		FarmService.Exit(player, false)
		if connections[player] then connections[player]:Disconnect() end
		connections[player], blocked[player], lastRequest[player] = nil, nil, nil
	end)
	for _, player in Players:GetPlayers() do watch(player) end
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do FarmService.Step(player) end
			task.wait(Config.ScanSeconds)
		end
	end)
end

return table.freeze(FarmService)
