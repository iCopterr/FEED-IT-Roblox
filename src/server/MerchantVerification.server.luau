if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="MerchantVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local data=require(services.DataService)
	local merchant=require(services.MerchantService)
	local farm=require(services.FarmService)
	local locks=require(services.FeedLocks)
	local plots=require(services.PlotService)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
	local feedConfig=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
	assert(adapter.IsMemory(),"Memory-only verification")
	local function check(value,name) assert(value,name);table.insert(checks,name) end
	local function waitFor(predicate,seconds)
		local deadline=os.clock()+(seconds or 120)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Verification timed out")
	end
	local stock=config.GetStock(12345);local again=config.GetStock(12345);local seen={}
	check(#stock==3 and table.concat(stock,"|")==table.concat(again,"|"),"Restock stock deterministic")
	for _,id in stock do check(config.Items[id]~=nil and not seen[id],"Stock item valid and unique "..id);seen[id]=true end
	check(config.GetRestockId(3599)==1 and config.GetRestockId(3600)==2,"Thirty-minute restock boundaries")
	local legacy=schema.CreateDefault();legacy.DataVersion=7;legacy.Tokens=nil;legacy.MerchantRestockId=nil;legacy.MerchantPurchases=nil
	local migrated=assert(schema.Migrate(legacy))
	check(migrated.DataVersion==8 and migrated.Tokens==0 and migrated.MerchantRestockId==0
		and next(migrated.MerchantPurchases)==nil and legacy.Tokens==nil,"v7 migration adds isolated merchant state")
	local invalid=assert(schema.Migrate(migrated));invalid.Tokens=config.TokenCap+1
	check(not schema.Validate(invalid),"Token cap enforced")
	invalid=assert(schema.Migrate(migrated));invalid.MerchantPurchases.bad=false
	check(not schema.Validate(invalid),"Merchant purchase map rejects false entries")
	local players=game:GetService("Players")
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b)
		and a.Character and b.Character and a.Character:FindFirstChild("HumanoidRootPart") and b.Character:FindFirstChild("HumanoidRootPart")
		and workspace:FindFirstChild("MysteryMerchant") and game.ReplicatedStorage:FindFirstChild("PrototypeMerchant")
		and game.ReplicatedStorage:FindFirstChild("FarmTokenDrop") end)
	local profile,other=data.GetData(a),data.GetData(b)
	local rootA,rootB=a.Character.HumanoidRootPart,b.Character.HumanoidRootPart
	rootA:SetNetworkOwner(nil);rootB:SetNetworkOwner(nil);rootA.Anchored=true;rootB.Anchored=true
	local point=workspace.MysteryMerchant.InteractionPoint
	local function near(root) root.CFrame=CFrame.new(point.Position+Vector3.new(0,3,5)) end
	near(rootA);near(rootB)
	local snap=merchant.HandleRequest(a,"Snapshot")
	check(snap.Ok and snap.Tokens==0 and #snap.Items==3 and snap.RestocksAt-snap.RestockId*config.RestockSeconds==config.RestockSeconds,
		"Snapshot exposes current private balance and three offers")
	check(snap.ServerNow>=snap.RestockId*config.RestockSeconds and snap.ServerNow<snap.RestocksAt,"Snapshot timer uses current epoch window")
	check(not merchant.HandleRequest(a,"Purchase",{},snap.RestockId,1).Ok,"Malformed slot rejected")
	check(not merchant.HandleRequest(a,"Grant",1,snap.RestockId,1).Ok,"Unknown action rejected")
	rootA.CFrame=CFrame.new(1000,5,1000);task.wait(.3)
	check(merchant.HandleRequest(a,"Purchase",1,snap.RestockId,1).Code=="TooFar","Distant purchase rejected")
	near(rootA);task.wait(.3)
	check(merchant.HandleRequest(a,"Purchase",1,snap.RestockId-1,1).Code=="Restocked","Stale restock rejected")
	task.wait(.3)
	check(merchant.HandleRequest(a,"Purchase",1,snap.RestockId,1).Code=="NotEnoughTokens","Insufficient Tokens reject without reward")
	profile.Tokens=20;other.Tokens=20;task.wait(.3)
	local selected=snap.Items[1];local beforeFood,beforeProtection=profile.Food,profile.ProtectionTokens
	local bought=merchant.HandleRequest(a,"Purchase",1,snap.RestockId,1)
	check(bought.Ok and profile.Tokens==20-selected.Price and profile.MerchantPurchases["1"],"Purchase charges exact Token price and records slot")
	if bought.RewardType=="Food" then check(profile.Food==beforeFood+bought.Amount,"Food offer grants configured amount")
	else check(profile.ProtectionTokens==beforeProtection+bought.Amount,"Protection offer grants configured amount") end
	local replay=merchant.HandleRequest(a,"Purchase",1,snap.RestockId,1)
	check(replay.ItemId==bought.ItemId and profile.Tokens==20-selected.Price,"Purchase replay cannot charge or reward twice")
	waitFor(function() return not locks.IsLocked(a) end);task.wait(.3)
	check(merchant.HandleRequest(a,"Purchase",1,snap.RestockId,2).Code=="Sold","Owned slot cannot be bought twice in one restock")
	local otherSnap=merchant.HandleRequest(b,"Snapshot");task.wait(.3)
	local otherBuy=merchant.HandleRequest(b,"Purchase",1,otherSnap.RestockId,1)
	check(otherBuy.Ok and other.MerchantPurchases["1"],"Stock purchase limit is per player")
	waitFor(function() return not locks.IsLocked(a) and not locks.IsLocked(b) end)
	assert(data.Save(a));local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.Tokens==profile.Tokens and loaded.MerchantRestockId==snap.RestockId and loaded.MerchantPurchases["1"],
		"Reload preserves Token balance and purchased slot")
	rootA.Anchored=false
	local work=plots.GetPlot(a).Farm.WorkPoint
	rootA.CFrame=CFrame.new(work.Position+Vector3.new(0,3,0));task.wait(.1)
	if not farm.IsFarming(a) then assert(farm.Enter(a)) end
	local beforeTokens=profile.Tokens
	task.wait(1.1);farm.Step(a)
	check(profile.Tokens==beforeTokens,"Entering farm does not grant an immediate Token roll")
	farm.SetTestTokenRoll(a,function() return 0 end);task.wait(1.1);farm.Step(a)
	check(profile.Tokens==beforeTokens+1,"Successful active-minute roll grants one Token")
	for _=1,20 do farm.Step(a) end
	check(profile.Tokens==beforeTokens+1,"Repeated farm steps cannot accelerate Token rolls")
	farm.SetTestTokenRoll(a,function() return 1 end);task.wait(1.1);farm.Step(a)
	check(profile.Tokens==beforeTokens+1,"Failed active-minute roll grants nothing")
	profile.Tokens=config.TokenCap
	farm.SetTestTokenRoll(a,function() return 0 end);task.wait(1.1);farm.Step(a)
	check(profile.Tokens==config.TokenCap,"Farm drop respects Token cap")
	farm.Exit(a,false)
	check(schema.Validate(profile) and schema.Validate(other),"Final merchant profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
