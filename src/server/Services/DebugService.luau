local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local PedestalService = require(script.Parent.PedestalService)
local Locks = require(script.Parent.FeedLocks)
local Overrides = require(script.Parent.DebugFeedOverrides)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Config = require(game.ReplicatedStorage.Shared.Config.DebugConfig)
local FeedConfig = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local FarmConfig = require(game.ReplicatedStorage.Shared.Config.FarmConfig)
local PetConfig = require(game.ReplicatedStorage.Shared.Config.PetConfig)
local sessions = {}
local Service = {}
local function integer(value, low, high)
	return type(value)=="number" and value==value and value%1==0 and value>=low and value<=high
end

function Service.HandleRequest(player, action, value, petId, sequence)
	-- Never expose debug writes in published servers or persistent Studio data.
	if not Overrides.Enabled() then return {Ok=false, Code="Disabled"} end
	if player.Parent ~= Players then return {Ok=false, Code="Loading"} end
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false, Code="Loading"} end
	local state = sessions[player]
	if not state then state={Sequence=0}; sessions[player]=state end
	local now = os.clock()
	if action == "Snapshot" then
		if now-(state.LastSnapshot or -math.huge)<Config.RequestCooldown then return {Ok=false, Code="Cooldown"} end
		state.LastSnapshot=now
		local pets={}
		for id, pet in data.Inventory do
			table.insert(pets,{PetId=id,Name=PetConfig.Species[pet.SpeciesId].DisplayName,FeedLevel=pet.FeedLevel,Placed=pet.Placed})
		end
		table.sort(pets,function(a,b) return a.PetId<b.PetId end)
		return {Ok=true,Pets=pets,Money=data.Money,Food=data.Food,FarmLevel=data.FarmLevel,
			NextSequence=state.Sequence+1,Forced=Overrides.Get(player),Busy=Locks.IsLocked(player)}
	end
	if not integer(sequence,1,9007199254740991) then return {Ok=false,Code="InvalidRequest"} end
	if sequence==state.Sequence and state.Last and state.Action==action and state.Value==value and state.PetId==petId then
		return table.clone(state.Last)
	end
	if sequence~=state.Sequence+1 then return {Ok=false,Code="StaleRequest"} end
	if now-(state.LastRequest or -math.huge)<Config.RequestCooldown then return {Ok=false,Code="Cooldown"} end
	state.LastRequest=now
	if Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local result={Ok=true,Code="Updated",NextSequence=sequence+1}
	if action=="AddMoney" or action=="AddFood" then
		local field=if action=="AddMoney" then "Money" else "Food"
		if not integer(value,1,Config.MaxGrant) or data[field]+value>Config.MaxBalance then return {Ok=false,Code="InvalidAmount"} end
		data[field]+=value
	elseif action=="SpawnPet" then
		if type(value)~="string" or not PetConfig.Species[value] then return {Ok=false,Code="InvalidSpecies"} end
		local count=0; for _ in data.Inventory do count+=1 end
		if count>=Config.MaxSpawnedInventory then return {Ok=false,Code="InventoryLimit"} end
		local pet=PetService.CreatePet(player,value)
		if not pet then return {Ok=false,Code="CreateFailed"} end
		result.PetId=pet.PetId
	elseif action=="SetFarmLevel" then
		if not integer(value,1,#FarmConfig.FoodPerSecond) then return {Ok=false,Code="InvalidLevel"} end
		data.FarmLevel=value
	elseif action=="SetPetLevel" or action=="ForceFeed" then
		if type(petId)~="string" or #petId>64 or not data.Inventory[petId] then return {Ok=false,Code="NotOwned"} end
		local pet=data.Inventory[petId]
		if action=="SetPetLevel" then
			if not integer(value,0,FeedConfig.MaxConfiguredLevel) then return {Ok=false,Code="InvalidLevel"} end
			if pet.Placed then return {Ok=false,Code="PickupFirst"} end
			pet.FeedLevel=value
			if PedestalService.GetPetId(player)==petId then PedestalService.EndPresentation(player,petId) end
		elseif not Overrides.Arm(player,petId,value) then return {Ok=false,Code="InvalidMode"} end
	else return {Ok=false,Code="InvalidRequest"} end
	state.Sequence=sequence
	state.Action,state.Value,state.PetId=action,value,petId
	state.Last=table.clone(result)
	-- Memory-only debug edits use normal profile autosave; no production writes.
	return result
end

function Service.Start()
	if not Overrides.Enabled() then return end
	local remote=Instance.new("RemoteFunction")
	remote.Name="PrototypeDebug"
	remote.OnServerInvoke=Service.HandleRequest
	remote.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player]=nil end)
end
return table.freeze(Service)
