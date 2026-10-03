if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="IndexVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local function check(value,label) assert(value,label);table.insert(checks,label) end
	local function waitFor(fn)
		local deadline=os.clock()+90
		repeat if fn() then return end;task.wait(.1) until os.clock()>deadline
		error("Index verification timed out")
	end
	local services=script.Parent.Services
	local Data=require(services.DataService)
	local Pets=require(services.PetService)
	local Eggs=require(services.EggService)
	local UI=require(services.UIService)
	local Locks=require(services.FeedLocks)
	local Schema=require(script.Parent.Data.PlayerDataSchema)
	check(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Isolated Studio memory data")
	waitFor(function() return #game.Players:GetPlayers()==2 end)
	local a,b=table.unpack(game.Players:GetPlayers())
	waitFor(function() return Data.IsLoaded(a) and Data.IsLoaded(b) and a.Character and a.Character:FindFirstChild("HumanoidRootPart") end)
	local profile=Data.GetData(a)
	profile.PetIndex={};Data.GetData(b).PetIndex={}
	local pet=assert(Pets.CreatePet(a,"test_common"))
	profile.Inventory[pet.PetId].FeedLevel=20
	local snap
	waitFor(function() snap=UI.HandleRequest(a,"IndexSnapshot");return snap.Ok end)
	check(snap.PetIndex.test_common,"Created species is discovered")
	check(snap.Inventory==nil and snap.Eggs==nil,"Index response contains no inventory or reserved eggs")
	check(UI.HandleRequest(a,"IndexSnapshot").Code=="Cooldown","Index spam is throttled")
	snap.PetIndex.test_common=nil;snap.PetIndex.supreme_pet_6=true
	check(profile.PetIndex.test_common and not profile.PetIndex.supreme_pet_6,"Snapshot mutation cannot change discovery save data")
	check(UI.HandleRequest(b,"IndexSnapshot").PetIndex.test_common==nil,"Discovery is private per player")
	check(UI.HandleRequest(a,"UnlockSpecies","supreme_pet_6").Code=="InvalidRequest","Clients cannot request unlocks")
	assert(Pets.RemovePet(a,pet.PetId))
	check(profile.PetIndex.test_common,"Removing a pet preserves its discovery")
	local clone=assert(Schema.Migrate(profile))
	check(clone.PetIndex.test_common,"Save migration preserves discoveries")
	check(Data.Save(a),"Discovery state saves successfully")
	profile.Money=1e9
	local bought=Eggs.BuyFromConveyor(a,"advanced_egg")
	check(bought.Ok,"Test egg purchased through server flow")
	waitFor(function() return not Locks.IsLocked(a) end)
	local egg=profile.IncubatingEggs[bought.EggUid]
	local species=egg.Pet.SpeciesId
	check(not profile.PetIndex[species],"Buying an egg does not reveal its reserved pet")
	-- Advance only this memory test egg to a valid ready placement.
	egg.PenPosition={X=0,Z=0};egg.StartedAt=os.time()-egg.HatchSeconds-1;egg.ReadyAt=egg.StartedAt+egg.HatchSeconds
	check(Schema.Validate(profile),"Ready test egg remains schema-valid")
	local hatched=Eggs.HandleRequest(a,"HatchRemote",bought.EggUid)
	check(hatched.Ok and profile.PetIndex[species],"Completed hatch unlocks its species after reward collection")
	waitFor(function() return not Locks.IsLocked(a) end)
	task.wait(.3)
	local afterHatch
	waitFor(function() afterHatch=UI.HandleRequest(a,"IndexSnapshot");return afterHatch.Ok end)
	check(afterHatch.PetIndex[species],"Hatch discovery reaches the index snapshot")
	local reports={}
	local report=Instance.new("RemoteEvent");report.Name="IndexVerificationReport"
	report.OnServerEvent:Connect(function(player,result) reports[player]=result end)
	report.Parent=game.ReplicatedStorage
	waitFor(function() return reports[a] and reports[b] end)
	for _,player in {a,b} do check(reports[player].Passed,"Index client: "..player.Name.." "..tostring(reports[player].Failure or "")) end
	check(Schema.Validate(profile),"Final profile remains valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
