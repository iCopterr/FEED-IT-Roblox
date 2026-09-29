local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local PetConfig=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local Variants=require(game.ReplicatedStorage.Shared.Config.VariantConfig)
local Data=require(script.Parent.DataService)
local Pets=require(script.Parent.PetService)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks=require(script.Parent.FeedLocks)
local Carry=require(script.Parent.CarryService)
local Placement=require(script.Parent.PlacementService)
local Plots=require(script.Parent.PlotService)
local Visuals=require(script.Parent.EggVisuals)
local PlacementConfig=require(game.ReplicatedStorage.Shared.Config.PlacementConfig)
local Service={}
local HatchAnimation=require(game.ReplicatedStorage.Shared.Config.HatchAnimationConfig)
local saving,sessions={},{}
local rng=Random.new()
local hatchOutcome
local hatchStarted

local function save(player,profile,afterSave)
	local token={};saving[player]=token
	task.spawn(function()
		while saving[player]==token and Data.GetData(player)==profile do
			local ok,saved,reason=pcall(Data.Save,player)
			if ok and saved then
				saving[player]=nil;Locks.Finish(player)
				if afterSave and player.Parent==Players then afterSave() end
				return
			end
			warn("[EggService] Save pending:",reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
end

-- Only the server conveyor calls this AFTER validating the offer and distance.
-- A client cannot request a price, hatch time, result or direct purchase here.
function Service.BuyFromConveyor(player,eggId)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	local profile=Data.GetData(player)
	local definition=Config.Definitions[eggId]
	if not profile or not Schema.Validate(profile) then return {Ok=false,Code="Loading"} end
	if not definition then return {Ok=false,Code="Unavailable"} end
	if saving[player] or Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	if profile.Money<definition.Price then return {Ok=false,Code="NotEnoughMoney"} end
	local pet,reason=Pets.PreparePet(player,Config.Pick(eggId,rng:NextNumber()),eggId)
	if not pet then return {Ok=false,Code="CreateFailed",Reason=reason} end
	pet.Variant=Variants.Pick(rng:NextInteger(1,Variants.Tickets))
	local id=HttpService:GenerateGUID(false)
	if profile.IncubatingEggs[id] then return {Ok=false,Code="CreateFailed"} end
	local egg={EggId=eggId,Pet=pet,StartedAt=0,ReadyAt=0,HatchSeconds=definition.HatchSeconds,PricePaid=definition.Price}
	assert(Locks.Begin(player,"EggPurchase"))
	local oldMoney=profile.Money
	profile.Money-=definition.Price
	profile.IncubatingEggs[id]=egg
	if not Schema.Validate(profile) then
		profile.Money=oldMoney;profile.IncubatingEggs[id]=nil;Locks.Finish(player)
		return {Ok=false,Code="InvalidData"}
	end
	require(script.Parent.TutorialProgress).Record(profile,"BoughtEgg",id,eggId)
	save(player,profile)
	if not Carry.GetPetId(player) and not Carry.GetEggId(player) then Carry.EquipEgg(player,id) end
	return {Ok=true,Code="Bought",EggUid=id,EggId=eggId,ReadyAt=egg.ReadyAt,Money=profile.Money}
end

function Service.HandleRequest(player,action,id,position)
	local remoteHatch=action=="HatchRemote"
	if remoteHatch then action="Hatch" end
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if action~="Snapshot" and action~="Hatch" and action~="Equip" and action~="Unequip" and action~="Place" then return {Ok=false,Code="InvalidRequest"} end
	local profile=Data.GetData(player)
	if not profile or not Schema.Validate(profile) then return {Ok=false,Code="Loading"} end
	local state=sessions[player]
	if not state then state={};sessions[player]=state end
	if action~="Snapshot" and (type(id)~="string" or #id==0 or #id>64) then return {Ok=false,Code="InvalidRequest"} end
	if action=="Hatch" and state.LastHatch and state.LastHatch.EggUid==id then return table.clone(state.LastHatch) end
	local now=os.clock()
	if now-(state[action] or -math.huge)<Config.RequestCooldown then return {Ok=false,Code="Cooldown"} end
	state[action]=now
	if action=="Snapshot" then
		local eggs={}
		for uid,egg in profile.IncubatingEggs do
			local definition=Config.Definitions[egg.EggId]
			-- Never replicate the reserved pet or its result before hatch.
			table.insert(eggs,{EggUid=uid,EggId=egg.EggId,StartedAt=egg.StartedAt,ReadyAt=egg.ReadyAt,
				Placed=egg.PenPosition~=nil,HatchSeconds=egg.HatchSeconds,
				Name=if definition then definition.DisplayName else egg.EggId})
		end
		table.sort(eggs,function(a,b) if a.StartedAt==b.StartedAt then return a.EggUid<b.EggUid end;return a.StartedAt<b.StartedAt end)
		return {Ok=true,Eggs=eggs,ServerNow=os.time(),Busy=Locks.IsLocked(player)}
	end
	if saving[player] or Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local egg=profile.IncubatingEggs[id]
	if not egg then return {Ok=false,Code="Unavailable"} end
	if action=="Equip" then
		local ok,reason=Carry.EquipEgg(player,id)
		return {Ok=ok,Code=if ok then "Equipped" else reason}
	elseif action=="Unequip" then
		if Carry.GetEggId(player)~=id then return {Ok=false,Code="NotCarrying"} end
		Carry.Unequip(player);return {Ok=true,Code="Unequipped"}
	elseif action=="Place" then
		if egg.PenPosition then return {Ok=false,Code="AlreadyPlaced"} end
		if Carry.GetEggId(player)~=id then return {Ok=false,Code="NotCarrying"} end
		local target=Placement.ResolvePosition(player,position)
		if not target then return {Ok=false,Code="OutsidePen"} end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position-target.Position).Magnitude>PlacementConfig.ClickDistance then return {Ok=false,Code="TooFar"} end
		local model=Visuals.Prepare(player,egg,target.Position)
		if not model then return {Ok=false,Code="TemplateUnavailable"} end
		local point=assert(Plots.GetPlacementOrigin(player)):PointToObjectSpace(target.Position)
		local previousStart,previousReady=egg.StartedAt,egg.ReadyAt
		assert(Locks.Begin(player,"EggPlacement"))
		egg.PenPosition={X=point.X,Z=point.Z}
		if egg.StartedAt==0 then egg.StartedAt=os.time();egg.ReadyAt=egg.StartedAt+egg.HatchSeconds end
		if not Schema.Validate(profile) or not Visuals.Install(player,id,model) then
			egg.PenPosition=nil;egg.StartedAt=previousStart;egg.ReadyAt=previousReady
			model:Destroy();Locks.Finish(player);return {Ok=false,Code="InvalidData"}
		end
		Carry.Unequip(player);Visuals.Reconcile(player,profile);save(player,profile)
		return {Ok=true,Code="Placed",EggUid=id,ReadyAt=egg.ReadyAt}
	end
	if not egg.PenPosition then return {Ok=false,Code="NotPlaced"} end
	if os.time()<egg.ReadyAt then return {Ok=false,Code="NotReady"} end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local model=Visuals.GetModel(player,id)
	local body=model and model:FindFirstChildWhichIsA("BasePart",true)
	if not humanoid or humanoid.Health<=0 or not root then return {Ok=false,Code="CharacterUnavailable"} end
	if not remoteHatch and (not body or (root.Position-body.Position).Magnitude>Config.HatchDistance) then return {Ok=false,Code="TooFar"} end
	assert(Locks.Begin(player,egg.Pet.PetId))
	local origin=if model then model:GetPivot() else root.CFrame*CFrame.new(0,0,-5)
	if model then model:SetAttribute("Hatching",true) end
	-- Keep the reserved pet in the saved egg until the server's reveal deadline.
	-- Leaving during this wait preserves the egg for a safe retry on reconnect.
	local endsAt=workspace:GetServerTimeNow()+HatchAnimation.Duration
	if hatchStarted then hatchStarted:FireClient(player,{Ok=true,Code="HatchStarted",EggUid=id,
		EggId=egg.EggId,HatchOrigin=origin,EndsAt=endsAt}) end
	repeat task.wait(math.max(.01,endsAt-workspace:GetServerTimeNow())) until workspace:GetServerTimeNow()>=endsAt
	if player.Parent~=Players or Data.GetData(player)~=profile or profile.IncubatingEggs[id]~=egg then
		if model and model.Parent then model:SetAttribute("Hatching",nil) end
		Locks.Finish(player)
		return {Ok=false,Code="Loading"}
	end
	local pet=egg.Pet
	local previousIndex=profile.PetIndex[pet.SpeciesId]
	profile.IncubatingEggs[id]=nil
	profile.Inventory[pet.PetId]=pet
	profile.PetIndex[pet.SpeciesId]=true
	if not Schema.Validate(profile) then
		profile.IncubatingEggs[id]=egg;profile.Inventory[pet.PetId]=nil
		profile.PetIndex[pet.SpeciesId]=previousIndex;Locks.Finish(player)
		if model and model.Parent then model:SetAttribute("Hatching",nil) end
		return {Ok=false,Code="InvalidData"}
	end
	local definition=PetConfig.Species[pet.SpeciesId]
	local result={Ok=true,Code="Hatched",EggUid=id,EggId=egg.EggId,SpeciesId=pet.SpeciesId,PetId=pet.PetId,Rarity=pet.Rarity,
		Variant=pet.Variant,PetName=Variants.Name(if definition then definition.DisplayName else pet.SpeciesId,pet.Variant),
		HatchOrigin=origin}
	state.LastHatch=table.clone(result)
	require(script.Parent.TutorialProgress).Record(profile,"Hatched",id,pet.PetId)
	Visuals.Reconcile(player,profile)
	save(player,profile,function()
		-- Reveal deadline passed; disclose the result only after persistence.
		local revealStart=workspace:GetServerTimeNow()
		result.RevealEndsAt=revealStart+HatchAnimation.PetRevealSeconds
		result.CollectStartsAt=result.RevealEndsAt+HatchAnimation.PetDissolveSeconds
		result.CollectEndsAt=result.CollectStartsAt+HatchAnimation.CollectSeconds
		if hatchOutcome then hatchOutcome:FireClient(player,result) end
		-- Ownership is already safely saved; only automatic carrying waits for the
		-- reward trail. No client acknowledgement can grant or duplicate the pet.
		local character=player.Character
		task.delay(result.CollectEndsAt-revealStart,function()
			if player.Parent~=Players or player.Character~=character or Data.GetData(player)~=profile
				or profile.Inventory[pet.PetId]~=pet or pet.Placed then return end
			if require(script.Parent.PedestalService).GetPetId(player)==pet.PetId then return end
			if not Carry.GetPetId(player) and not Carry.GetEggId(player) then Carry.Equip(player,pet.PetId) end
		end)
	end)
	return result
end

function Service.Start()
	hatchStarted=Instance.new("RemoteEvent");hatchStarted.Name="HatchStarted";hatchStarted.Parent=game.ReplicatedStorage
	hatchOutcome=Instance.new("RemoteEvent");hatchOutcome.Name="HatchOutcome";hatchOutcome.Parent=game.ReplicatedStorage
	Visuals.OnHatch=function(player,id) return Service.HandleRequest(player,"Hatch",id) end
	for id,definition in Config.Definitions do
		assert(type(id)=="string" and definition.Price>=0 and definition.Price<math.huge,"Invalid egg price")
		assert(definition.HatchSeconds>=0 and definition.HatchSeconds%1==0 and definition.HatchSeconds<math.huge,"Invalid hatch timer")
		assert(#definition.Results>0,"Empty egg pool")
		local total=0
		for _,entry in definition.Results do
			assert(PetConfig.Species[entry.SpeciesId] and entry.Weight>0 and entry.Weight<math.huge,"Invalid egg result")
			total+=entry.Weight
		end
		assert(total<math.huge,"Invalid total hatch weight")
	end
	local remote=Instance.new("RemoteFunction");remote.Name="PrototypeEgg"
	remote.OnServerInvoke=Service.HandleRequest;remote.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) saving[player],sessions[player]=nil,nil;Visuals.Clear(player) end)
	task.spawn(function()
		while true do
			for _,player in Players:GetPlayers() do Visuals.Reconcile(player,Data.GetData(player)) end
			task.wait(1)
		end
	end)
end

return table.freeze(Service)
