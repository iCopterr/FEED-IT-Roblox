local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
local PetConfig=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local DataService=require(script.Parent.DataService)
local PetService=require(script.Parent.PetService)
local PlotService=require(script.Parent.PlotService)
local MoneyService=require(script.Parent.MoneyService)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Service={}
local offers,lastRequest,lastPurchase,saving={},{},{},{}
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
			and game:GetService("StudioTestService"):GetTestArgs()=="ConveyorVerification"
			and require(script.Parent.Parent.Data.DataStoreAdapter).IsMemory(),"Test-only roll")
	end
	local count=0
	for _ in offers do count+=1 end
	if not visuals or count>=Config.MaxOffers then return nil,"Full" end
	local definition=Config.Pick(if testRoll~=nil then testRoll else rng:NextNumber())
	local template=workspace.PetTemplates:FindFirstChild(definition.SpeciesId)
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
		local body=assert(model:FindFirstChildWhichIsA("BasePart",true),"Pet template has no body")
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
		end
		local bounds,size=model:GetBoundingBox()
		local a,b=conveyor.Start.Position,conveyor.Finish.Position
		from=CFrame.lookAt(a,b)*CFrame.new(0,size.Y/2,0)*bounds:ToObjectSpace(model:GetPivot())
		to=from+(b-a)
		model:PivotTo(from)
		model:SetAttribute("OfferId",id)
		model:SetAttribute("SpeciesId",definition.SpeciesId)
		model:SetAttribute("Rarity",definition.Rarity)
		model:SetAttribute("Price",definition.Price)
		model:SetAttribute("From",from);model:SetAttribute("To",to)
		model:SetAttribute("StartedAt",started)
		local label=game.ReplicatedStorage.ConveyorPetLabel:Clone()
		label.NameLabel.Text=PetConfig.Species[definition.SpeciesId].DisplayName
		label.Rarity.Text=string.upper(definition.Rarity)
		label.Rarity.TextColor3=definition.Color
		label.Price.Text=string.format("%g MONEY",definition.Price)
		label.Adornee=body;label.Parent=body
		local prompt=Instance.new("ProximityPrompt")
		prompt.Name="BuyConveyorPet"
		prompt.ActionText=string.format("Buy • %g Money",definition.Price)
		prompt.ObjectText=definition.Rarity.." Pet"
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
	if saving[player] then return {Ok=false,Code="Saving"} end
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
	local price=offer.Definition.Price
	if data.Money<price then return {Ok=false,Code="NotEnoughMoney"} end
	-- No yield between validation, payment, pet creation and consuming the offer.
	-- Consequently simultaneous players cannot both buy the same display pet.
	local oldMoney=data.Money
	data.Money-=price
	local pet,reason=PetService.CreatePet(player,offer.Definition.SpeciesId)
	if not pet then data.Money=oldMoney;return {Ok=false,Code="CreateFailed",Reason=reason} end
	remove(id)
	local result={Ok=true,Code="Bought",OfferId=id,PetId=pet.PetId,Rarity=pet.Rarity,
		Money=data.Money,MoneyAt=os.clock(),IncomePerSecond=MoneyService.GetRate(player)}
	lastPurchase[player]=table.clone(result)
	local token={};saving[player]=token
	if changed then changed:FireClient(player,result) end
	task.spawn(function()
		while saving[player]==token and DataService.GetData(player)==data do
			local ok,saved,errorMessage=pcall(DataService.Save,player)
			if ok and saved then saving[player]=nil;return end
			warn("[Conveyor] Purchase save pending:",errorMessage or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
	return result
end

function Service.Start()
	conveyor=assert(workspace:FindFirstChild("PetConveyor"),"Authored PetConveyor missing")
	assert(conveyor.Start and conveyor.Finish,"Conveyor markers missing")
	for _,entry in Config.Offers do
		assert(PetConfig.Species[entry.SpeciesId].Rarity==entry.Rarity,"Conveyor rarity mismatch")
		assert(entry.Price>=0 and entry.Price<math.huge and entry.Weight>0,"Invalid conveyor balance")
	end
	visuals=Instance.new("Folder");visuals.Name="Offers";visuals.Parent=conveyor
	local remote=Instance.new("RemoteFunction");remote.Name="BuyConveyorPet"
	remote.OnServerInvoke=Service.HandlePurchase;remote.Parent=game.ReplicatedStorage
	changed=Instance.new("RemoteEvent");changed.Name="ConveyorPurchaseChanged";changed.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) lastRequest[player],lastPurchase[player],saving[player]=nil,nil,nil end)
	local verification=game:GetService("RunService"):IsStudio()
		and game:GetService("StudioTestService"):GetTestArgs()=="ConveyorVerification"
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
