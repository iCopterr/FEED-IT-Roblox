local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
local EggConfig=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local EggLabelAnchor=require(game.ReplicatedStorage.Shared.EggLabelAnchor)
local DataService=require(script.Parent.DataService)
local EggService=require(script.Parent.EggService)
local PlotService=require(script.Parent.PlotService)
local MoneyService=require(script.Parent.MoneyService)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Service={}
local numberText=require(game.ReplicatedStorage.Shared.NumberFormat).Money
local offers,lastRequest,lastPurchase={},{},{}
local rng=Random.new()
local conveyor,visuals,changed

local function position(offer,now)
	return offer.From:Lerp(offer.To,math.clamp((now-offer.StartedAt)/Config.TravelSeconds,0,1))
end
local function remove(id)
	local offer=offers[id]
	if not offer then return end
	offers[id]=nil
	offer.Model:Destroy()
end
function Service.Step()
	local now=workspace:GetServerTimeNow()
	for id,offer in offers do
		if now>=offer.ExpiresAt or offer.Model.Parent~=visuals then remove(id)
		else offer.Model:PivotTo(position(offer,now)) end
	end
end

function Service.SpawnOffer(testRoll)
	if testRoll~=nil then
		assert(game:GetService("RunService"):IsStudio()
			and (game:GetService("StudioTestService"):GetTestArgs()=="ConveyorVerification" or game:GetService("StudioTestService"):GetTestArgs()=="EggVerification")
			and require(script.Parent.Parent.Data.DataStoreAdapter).IsMemory(),"Test-only roll")
	end
	local count=0
	for _ in offers do count+=1 end
	if not visuals or count>=Config.MaxOffers then return nil,"Full" end
	local definition=Config.Pick(if testRoll~=nil then testRoll else rng:NextNumber())
	local egg=EggConfig.Definitions[definition.EggId]
	local template=workspace.EggTemplates:FindFirstChild(egg.TemplateName)
	if not template or not template:IsA("Model") then return nil,"TemplateUnavailable" end
	for _,item in template:GetDescendants() do
		if item:IsA("LuaSourceContainer") then return nil,"TemplateUnavailable" end
	end
	local model=template:Clone()
	local id=HttpService:GenerateGUID(false)
	local started=workspace:GetServerTimeNow()
	local from,to
	local ok,reason=pcall(function()
		model.Name=id
		model:ScaleTo(1)
		local body=assert(model:FindFirstChildWhichIsA("BasePart",true),"Egg template has no body")
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
		end
		local bounds,size=model:GetBoundingBox()
		local a,b=conveyor.Start.Position,conveyor.Finish.Position
		from=CFrame.lookAt(a,b)*CFrame.new(0,size.Y/2,0)*bounds:ToObjectSpace(model:GetPivot())
		to=from+(b-a)
		model:PivotTo(from)
		model:SetAttribute("OfferId",id)
		model:SetAttribute("EggId",definition.EggId)
		model:SetAttribute("Price",egg.Price)
		model:SetAttribute("From",from);model:SetAttribute("To",to)
		model:SetAttribute("StartedAt",started)
		local label=game.ReplicatedStorage.ConveyorPetLabel:Clone()
		label.NameLabel.Text=egg.DisplayName
		label.Rarity.Visible=false
		label.Price.Position=UDim2.fromOffset(0,28)
		label.Size=UDim2.fromOffset(240,56)
		label.Price.Text="$"..numberText(egg.Price)
		label.Price.TextColor3=Color3.fromRGB(110,255,100)
		EggLabelAnchor.Bind(model,label)
		local prompt=Instance.new("ProximityPrompt")
		prompt.Name="BuyConveyorEgg"
		prompt.ActionText="Buy • "..numberText(egg.Price).." Money"
		prompt.ObjectText=egg.DisplayName
		prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
		prompt.HoldDuration=Config.BuyHoldSeconds;prompt.MaxActivationDistance=Config.BuyDistance
		prompt.RequiresLineOfSight=false;prompt.Parent=body
		model.Parent=visuals
	end)
	if not ok then model:Destroy();warn("[Conveyor] Visual preparation failed:",reason);return nil,"TemplateUnavailable" end
	offers[id]={Model=model,Definition=definition,From=from,To=to,StartedAt=started,ExpiresAt=started+Config.TravelSeconds}
	return id,model
end

function Service.HandlePurchase(player,id)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if type(id)~="string" or #id==0 or #id>64 then return {Ok=false,Code="InvalidRequest"} end
	local previous=lastPurchase[player]
	if previous and previous.OfferId==id then return table.clone(previous) end
	local now=os.clock()
	if now-(lastRequest[player] or -math.huge)<Config.RequestCooldown then return {Ok=false,Code="Cooldown"} end
	lastRequest[player]=now
	local data=DataService.GetData(player)
	if not data or not Schema.Validate(data) or not PlotService.GetPlot(player) then return {Ok=false,Code="Loading"} end
	local offer=offers[id]
	local serverNow=workspace:GetServerTimeNow()
	if not offer or offer.Model.Parent~=visuals or serverNow>=offer.ExpiresAt then return {Ok=false,Code="Unavailable"} end
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health<=0 then return {Ok=false,Code="Unavailable"} end
	-- Distance is evaluated from the server timeline, never client-supplied position.
	if (root.Position-position(offer,serverNow).Position).Magnitude>Config.BuyDistance then return {Ok=false,Code="TooFar"} end
	-- The egg service atomically charges, reserves the result and starts incubation.
	local result=EggService.BuyFromConveyor(player,offer.Definition.EggId)
	if not result.Ok then return result end
	remove(id)
	result.OfferId=id
	result.MoneyAt=os.clock();result.IncomePerSecond=MoneyService.GetRate(player)
	lastPurchase[player]=table.clone(result)
	if changed then changed:FireClient(player,result) end
	return result
end

function Service.Start()
	conveyor=assert(workspace:FindFirstChild("PetConveyor"),"Authored PetConveyor missing")
	assert(conveyor.Start and conveyor.Finish,"Conveyor markers missing")
	for _,entry in Config.Offers do
		assert(EggConfig.Definitions[entry.EggId],"Unknown conveyor egg")
		assert(entry.Weight>0 and entry.Weight<math.huge,"Invalid conveyor weight")
	end
	visuals=Instance.new("Folder");visuals.Name="Offers";visuals.Parent=conveyor
	local remote=Instance.new("RemoteFunction");remote.Name="BuyConveyorEgg"
	remote.OnServerInvoke=Service.HandlePurchase;remote.Parent=game.ReplicatedStorage
	changed=Instance.new("RemoteEvent");changed.Name="ConveyorPurchaseChanged";changed.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) lastRequest[player],lastPurchase[player]=nil,nil end)
	local verification=game:GetService("RunService"):IsStudio()
		and (game:GetService("StudioTestService"):GetTestArgs()=="ConveyorVerification" or game:GetService("StudioTestService"):GetTestArgs()=="EggVerification")
	task.spawn(function()
		local nextSpawn=0
		while conveyor.Parent do
			Service.Step()
			if not verification and os.clock()>=nextSpawn then
				nextSpawn=os.clock()+Config.SpawnSeconds
				Service.SpawnOffer()
			end
			task.wait(Config.StepSeconds)
		end
		for id in offers do remove(id) end
	end)
end
return table.freeze(Service)
