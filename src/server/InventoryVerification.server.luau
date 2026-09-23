if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="InventoryVerification" then return end
local signal=Instance.new("RemoteEvent")
signal.Name="InventoryVerificationReport";signal.Parent=game.ReplicatedStorage
local reports={}
signal.OnServerEvent:Connect(function(player,result) reports[player]=result end)
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local data=require(services.DataService)
	local pets=require(services.PetService)
	local ui=require(services.UIService)
	local carry=require(services.CarryService)
	local placement=require(services.PlacementService)
	local plots=require(services.PlotService)
	local eggs=require(services.EggService)
	local locks=require(services.FeedLocks)
	assert(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory tests only")
	local function check(value,name) assert(value,name);table.insert(checks,name) end
	local function waitFor(predicate)
		local untilTime=os.clock()+90
		repeat if predicate() then return end;task.wait(.1) until os.clock()>untilTime
		error("Inventory verification timed out")
	end
	local players=game.Players
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	local function readSnapshot()
		local result
		waitFor(function() result=ui.HandleRequest(a,"Snapshot");return result.Ok end)
		return result
	end
	local function action(name,id,value)
		local result
		waitFor(function() result=ui.HandleRequest(a,name,id,value);return result.Code~="Cooldown" end)
		return result
	end
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a)
		and a.Character and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("PrototypeEgg") end)
	local own=assert(pets.CreatePet(a,"test_rare"))
	local foreign=assert(pets.CreatePet(b,"test_epic"))
	local profile=data.GetData(a)
	profile.Inventory[own.PetId].FeedLevel=12
	local root=a.Character.HumanoidRootPart
	require(services.FarmService).Exit(a,false)
	root.Anchored=false
	root:SetNetworkOwner(nil);root.Anchored=true
	root.CFrame=CFrame.new(plots.GetPlot(a).Pen.Floor.Position+Vector3.new(0,5,0))
	task.wait(.3)
	local state=readSnapshot()
	check(type(state.Eggs)=="table" and state.ServerNow~=nil,"Current public egg snapshot is running")
	check(state.Ok and state.Inventory[own.PetId] and not state.Inventory[foreign.PetId],"Snapshot contains only owned pets")
	local equipped=action("EquipPet",own.PetId)
	check(equipped.Ok,"Inventory equip succeeds: "..tostring(equipped.Code))
	check(carry.GetPetId(a)==own.PetId,"Equip retains authoritative pet identity")
	task.wait(.3)
	local unequipped=action("UnequipPet",own.PetId)
	check(unequipped.Ok and not carry.GetPetId(a),"Quick-slot unequip returns to inventory: "..tostring(unequipped.Code))
	task.wait(.3)
	check(not action("EquipPet",foreign.PetId).Ok,"Cannot equip another player's pet")
	task.wait(.3)
	check(action("SetLocked",own.PetId,true).Ok and profile.Inventory[own.PetId].Locked,"Inventory lock works")
	assert(placement.PlacePet(a,own.PetId))
	task.wait(.3)
	check(action("EquipPet",own.PetId).Code=="HoldToPickup","Hotbar cannot remotely pick up a placed pet")
	assert(placement.PickupPet(a,own.PetId))
	assert(placement.PlacePet(a,own.PetId))
	a.Character.HumanoidRootPart.CFrame=CFrame.new(0,8,-170)
	task.wait(.3)
	check(not action("PickupRemote",foreign.PetId).Ok,"Remote pickup rejects foreign ID")
	task.wait(.3)
	check(action("PickupRemote",own.PetId).Ok and not profile.Inventory[own.PetId].Placed,"Remote pickup works away from pen")
	task.wait(.3)
	check(not action("PickupRemote",own.PetId).Ok,"Remote pickup replay cannot duplicate")
	profile.Money=100000
	waitFor(function() return not locks.IsLocked(a) end)
	local bought=eggs.BuyFromConveyor(a,"prototype_egg")
	check(bought.Ok,"Egg acquired for mixed inventory: "..tostring(bought.Code).." "..tostring(bought.Reason))
	waitFor(function() return not locks.IsLocked(a) end)
	task.wait(.3)
	state=readSnapshot()
	check(#state.Eggs==1 and state.Eggs[1].EggUid==bought.EggUid,"Unified inventory includes owned egg")
	check(state.Eggs[1].Pet==nil and state.Eggs[1].SpeciesId==nil and state.Eggs[1].Rarity==nil,"Private hatch result never replicated")
	check(state.CarriedEggUid==bought.EggUid,"Snapshot reports held egg")
	check(eggs.HandleRequest(a,"Unequip",bought.EggUid).Ok,"Egg quick-slot put away uses existing service")
	check(eggs.HandleRequest(a,"Equip",bought.EggUid).Ok,"Egg quick-slot equip uses existing service")
	check(profile.Inventory[own.PetId]~=nil and profile.IncubatingEggs[bought.EggUid]~=nil,"Quick slots do not consume or duplicate ownership")
	signal:SetAttribute("FixturesReady",true)
	waitFor(function() return reports[a] and reports[b] end)
	for _,player in {a,b} do
		local report=reports[player]
		check(report.passed,"Client UI startup/layout checks: "..tostring(report.failure))
		for _,name in report.checks or {} do table.insert(checks,"Client "..player.Name..": "..name) end
	end
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile),"Final profile remains valid")
end,debug.traceback)
signal:Destroy()
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
