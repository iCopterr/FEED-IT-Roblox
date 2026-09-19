local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local PetConfig=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local Data=require(script.Parent.DataService)
local Pets=require(script.Parent.PetService)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks=require(script.Parent.FeedLocks)
local Service={}
local saving,sessions={},{}
local rng=Random.new()

local function save(player,profile)
	local token={};saving[player]=token
	task.spawn(function()
		while saving[player]==token and Data.GetData(player)==profile do
			local ok,saved,reason=pcall(Data.Save,player)
			if ok and saved then saving[player]=nil;Locks.Finish(player);return end
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
	local count=0
	for _ in profile.IncubatingEggs do count+=1 end
	if count>=Config.MaxIncubatingEggs then return {Ok=false,Code="IncubatorFull"} end
	if profile.Money<definition.Price then return {Ok=false,Code="NotEnoughMoney"} end
	local pet,reason=Pets.PreparePet(player,Config.Pick(eggId,rng:NextNumber()),eggId)
	if not pet then return {Ok=false,Code="CreateFailed",Reason=reason} end
	local id=HttpService:GenerateGUID(false)
	if profile.IncubatingEggs[id] then return {Ok=false,Code="CreateFailed"} end
	local now=os.time()
	local egg={EggId=eggId,Pet=pet,StartedAt=now,ReadyAt=now+definition.HatchSeconds,PricePaid=definition.Price}
	assert(Locks.Begin(player,"EggPurchase"))
	local oldMoney=profile.Money
	profile.Money-=definition.Price
	profile.IncubatingEggs[id]=egg
	if not Schema.Validate(profile) then
		profile.Money=oldMoney;profile.IncubatingEggs[id]=nil;Locks.Finish(player)
		return {Ok=false,Code="InvalidData"}
	end
	save(player,profile)
	return {Ok=true,Code="Bought",EggUid=id,EggId=eggId,ReadyAt=egg.ReadyAt,Money=profile.Money}
end

function Service.HandleRequest(player,action,id)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if action~="Snapshot" and action~="Hatch" then return {Ok=false,Code="InvalidRequest"} end
	local profile=Data.GetData(player)
	if not profile or not Schema.Validate(profile) then return {Ok=false,Code="Loading"} end
	local state=sessions[player]
	if not state then state={};sessions[player]=state end
	if action=="Hatch" and (type(id)~="string" or #id==0 or #id>64) then return {Ok=false,Code="InvalidRequest"} end
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
				Name=if definition then definition.DisplayName else egg.EggId})
		end
		table.sort(eggs,function(a,b) if a.StartedAt==b.StartedAt then return a.EggUid<b.EggUid end;return a.StartedAt<b.StartedAt end)
		return {Ok=true,Eggs=eggs,ServerNow=os.time(),Busy=Locks.IsLocked(player),MaxSlots=Config.MaxIncubatingEggs}
	end
	if saving[player] or Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local egg=profile.IncubatingEggs[id]
	if not egg then return {Ok=false,Code="Unavailable"} end
	if os.time()<egg.ReadyAt then return {Ok=false,Code="NotReady"} end
	assert(Locks.Begin(player,egg.Pet.PetId))
	local pet=egg.Pet
	local previousIndex=profile.PetIndex[pet.SpeciesId]
	profile.IncubatingEggs[id]=nil
	profile.Inventory[pet.PetId]=pet
	profile.PetIndex[pet.SpeciesId]=true
	if not Schema.Validate(profile) then
		profile.IncubatingEggs[id]=egg;profile.Inventory[pet.PetId]=nil
		profile.PetIndex[pet.SpeciesId]=previousIndex;Locks.Finish(player)
		return {Ok=false,Code="InvalidData"}
	end
	local definition=PetConfig.Species[pet.SpeciesId]
	local result={Ok=true,Code="Hatched",EggUid=id,PetId=pet.PetId,Rarity=pet.Rarity,
		PetName=if definition then definition.DisplayName else pet.SpeciesId}
	state.LastHatch=table.clone(result)
	save(player,profile)
	return result
end

function Service.Start()
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
	Players.PlayerRemoving:Connect(function(player) saving[player],sessions[player]=nil,nil end)
end

return table.freeze(Service)
