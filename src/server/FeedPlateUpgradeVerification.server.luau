if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="FeedPlateUpgradeVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local data=require(services.DataService)
	local plots=require(services.PlotService)
	local upgrade=require(services.FeedPlateUpgradeService)
	local feed=require(services.FeedService)
	local pets=require(services.PetService)
	local carry=require(services.CarryService)
	local locks=require(services.FeedLocks)
	local resolver=require(services.FeedResolver)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.FeedPlateConfig)
	local farm=require(game.ReplicatedStorage.Shared.Config.FarmConfig)
	assert(adapter.IsMemory(),"Memory data only")
	local function check(v,n) assert(v,n);table.insert(checks,n) end
	local function waitFor(f)
		local deadline=os.clock()+90
		repeat if f() then return end;task.wait(.1) until os.clock()>deadline
		error("Timed out")
	end
	local function random(values)
		local i=0
		return function() i+=1;return assert(values[i],"Extra RNG roll") end
	end
	local legacy=schema.CreateDefault()
	legacy.DataVersion=3;legacy.FeedPlateLevel=nil;legacy.Money=12345;legacy.FarmLevel=7
	local migrated=assert(schema.Migrate(legacy))
	check(migrated.FeedPlateLevel==1 and migrated.DataVersion==4 and migrated.Money==12345 and migrated.FarmLevel==7 and legacy.FeedPlateLevel==nil,"v3 migration preserves progress without mutating source")
	for _,invalid in {0,-1,1.5,math.huge} do
		migrated.FeedPlateLevel=invalid
		check(not schema.Validate(migrated),"Reject invalid plate level "..invalid)
	end
	for level=2,10 do check(config.UpgradeCost[level]==farm.UpgradeCost[level],"Farm-matched price "..level) end
	check(math.abs(config.GetRisk(.2,10)-.11)<1e-9 and config.GetRisk(.88,10)>.48,"Relative reduction preserves late risk")
	check(resolver.Roll(14,random({.15,.9}),.2).Code=="Explosion","Baseline roll explodes")
	check(resolver.Roll(14,random({.15,.1}),.11).Code=="Success","Same roll survives upgraded risk")
	check(resolver.Roll(14,random({0,0}),.11).Code=="MiracleSave","Miracle order unchanged")
	local players=game:GetService("Players")
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b)
		and a.Character and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("FeedPlateUpgrade") end)
	local profile=data.GetData(a)
	local plot=plots.GetPlot(a)
	local root=a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil);root.Anchored=true
	local board=workspace.FeedPlateUpgradeSigns[plot.Name].Board
	local function near() root.CFrame=CFrame.new(board.Position+Vector3.new(0,0,5)) end
	local function request(name,level) task.wait(.55);return upgrade.HandleRequest(a,name or plot.Name,level or profile.FeedPlateLevel) end
	check(#workspace.FeedPlateUpgradeSigns:GetChildren()==6,"Six authored upgrade signs")
	check(upgrade.HandleRequest(a,{},1).Code=="InvalidRequest","Malformed request rejected")
	check(upgrade.HandleRequest(a,plot.Name,0/0).Code=="InvalidRequest","NaN rejected")
	near()
	check(request(plots.GetPlot(b).Name).Code=="NotOwner","Foreign plot rejected")
	root.CFrame=CFrame.new(0,100,0)
	check(request().Code=="TooFar","Distant purchase rejected")
	near();profile.Money=0
	check(request().Code=="NotEnoughMoney","Unaffordable purchase rejected")
	profile.Money=5e15
	local food,farmLevel=profile.Food,profile.FarmLevel
	locks.Begin(a,"test")
	check(request().Code=="Busy","Feed/Revive lock blocks purchase")
	locks.Finish(a)
	for level=1,9 do
		local money=profile.Money
		local result=request()
		check(result.Ok and profile.FeedPlateLevel==level+1 and profile.Money==money-config.UpgradeCost[level+1],"Atomic purchase level "..(level+1))
		check(not upgrade.HandleRequest(a,plot.Name,level).Ok,"Duplicate click rejected "..level)
		waitFor(function() return not locks.IsLocked(a) end)
		check(request(nil,level).Code=="LevelChanged","Stale level rejected "..level)
	end
	check(request().Code=="MaxLevel","Maximum enforced")
	check(profile.Food==food and profile.FarmLevel==farmLevel and data.GetData(b).FeedPlateLevel==1,"Food farm and foreign progress unchanged")
	local pet=assert(pets.CreatePet(a,"test_common"))
	profile.Inventory[pet.PetId].FeedLevel=14
	profile.Food=1e12
	root.CFrame=CFrame.new(plot.FeedPlate.Dish.Position+Vector3.new(0,3,6))
	assert(carry.Equip(a,pet.PetId));assert(carry.PlaceOnPlate(a,pet.PetId))
	local snapshot=feed.HandleRequest(a,"Snapshot")
	check(math.abs(snapshot.Risk-.11)<1e-9 and snapshot.BaseRisk==.2 and snapshot.PlateLevel==10,"Feed snapshot shows actual reduced risk")
	feed.SetTestRandom(a,random({.15,.1}))
	local result=feed.HandleRequest(a,"Feed",pet.PetId,1)
	check(result.Accepted and result.Code=="Success" and profile.Inventory[pet.PetId].FeedLevel==15,"Real feed uses server plate reduction")
	waitFor(function() return not locks.IsLocked(a) end)
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.FeedPlateLevel==10 and loaded.Inventory[pet.PetId].FeedLevel==15,"Saved reload retains plate and unique pet progression")
	check(schema.Validate(profile) and schema.Validate(data.GetData(b)),"Both profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
