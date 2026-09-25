if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="FoodShopVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local reports={}
	local report=Instance.new("RemoteEvent")
	report.Name="FoodShopVerificationReport"
	report.OnServerEvent:Connect(function(player,result) reports[player]=result end)
	report.Parent=game.ReplicatedStorage
	local services=script.Parent.Services
	local Data=require(services.DataService)
	local Pets=require(services.PetService)
	local Plots=require(services.PlotService)
	local Merchant=require(services.MerchantService)
	local Feed=require(services.FeedService)
	local Rescue=require(services.ReviveService)
	local Plate=require(services.PedestalService)
	local Locks=require(services.FeedLocks)
	local Overrides=require(services.DebugFeedOverrides)
	local Schema=require(script.Parent.Data.PlayerDataSchema)
	local Food=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
	local MerchantConfig=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
	local FeedConfig=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
	local function check(value,label) assert(value,label);table.insert(checks,label) end
	local function waitFor(fn,seconds)
		local deadline=os.clock()+(seconds or 60)
		repeat if fn() then return end;task.wait(.1) until os.clock()>deadline
		error("Timed out waiting for test state")
	end
	check(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only player data")
	waitFor(function() return #game.Players:GetPlayers()==2 end)
	local a,b=table.unpack(game.Players:GetPlayers())
	waitFor(function() return Data.IsLoaded(a) and Data.IsLoaded(b) and Plots.GetPlot(a)
		and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
		and game.ReplicatedStorage:FindFirstChild("PrototypeRevive") end)
	local profile=Data.GetData(a)
	local root=a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil);root.Anchored=true
	root.CFrame=workspace.MysteryMerchant.InteractionPoint.CFrame+Vector3.new(0,3,0)
	profile.Money=1e9
	local restock=MerchantConfig.GetRestockId(os.time())
	local stock=MerchantConfig.GetStock(restock)
	check(MerchantConfig.RestockSeconds==5*60,"Merchant restocks every five minutes")
	check(stock[1]=="basic" and stock[2]~=stock[3],"Basic plus two distinct special offers")
	check(#Food.Order==7 and Food.Types.fresh.Reduction==.08 and Food.Types.fortified.Reduction==.22
		and Food.Types.enchanted.Reduction==.38,"Seven ordered food types use configured risk tiers")
	local seen={}
	for id=restock,restock+500 do
		local sample=MerchantConfig.GetStock(id)
		for index=2,#sample do seen[sample[index]]=true end
	end
	for _,id in Food.Order do if id~="basic" then check(seen[id],id.." appears in deterministic restocks") end end
	local purchase=Merchant.HandleRequest(a,"Purchase",1,restock,1)
	check(purchase.Ok and purchase.Remaining==4 and profile.Food==5 and profile.Money==1e9-100,"Basic purchase uses Money and grants servings")
	check(Merchant.HandleRequest(a,"Purchase",1,restock,1).Ok and profile.Food==5,"Duplicate purchase never charges twice")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",1,restock,2).Ok and profile.Food==10,"Basic remains available within stock")
	for sequence=3,5 do
		waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
		local more=Merchant.HandleRequest(a,"Purchase",1,restock,sequence)
		check(more.Ok and more.Remaining==5-sequence and profile.Food==sequence*5,"Basic stock purchase "..sequence)
	end
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",1,restock,6).Code=="Sold" and profile.Food==25,"Basic is limited to five purchases per restock")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	local shop
	waitFor(function() shop=Merchant.HandleRequest(a,"Snapshot");return shop.Ok end)
	check(shop.Items[1].Purchased and shop.Items[1].Remaining==0 and shop.Items[1].StockLimit==5,"Basic sold-out state is public to its owner")
	task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",2,restock,6).Ok,"Special food purchase")
	local special=stock[2]
	check(Food.Count(profile,special)==Food.Types[special].Amount,"Correct special food granted")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",2,restock,7).Code=="Sold","Special offer has personal purchase limit")
	task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",1,restock-1,7).Code=="Restocked","Stale restock rejected")
	task.wait(.3)
	profile.Money=0
	check(Merchant.HandleRequest(a,"Purchase",3,restock,7).Code=="NotEnoughMoney","Insufficient Money cannot grant food")
	check(Data.GetData(b).Foods[special]==nil,"Another player's stock and food are untouched")
	local dish=Plots.GetPlot(a).FeedPlate.Dish
	root.CFrame=CFrame.new(dish.Position+Vector3.new(0,3,6))
	local pet=assert(Pets.CreatePet(a,"test_rare"))
	profile.Inventory[pet.PetId].FeedLevel=20
	profile.Inventory[pet.PetId].Variant="Rainbow"
	profile.Inventory[pet.PetId].Locked=true
	assert(Plate.Place(a,pet.PetId))
	waitFor(function() return reports[a] and reports[b] end,40)
	for _,player in {a,b} do
		check(reports[player].Passed,"Client inventory/feed UI: "..player.Name.." "..tostring(reports[player].Failure or ""))
	end
	check(Feed.HandleRequest(a,"ProtectedFeed",pet.PetId,1).Code=="InvalidRequest","Old Protection remote action removed")
	local snap
	waitFor(function() snap=Feed.HandleRequest(a,"Snapshot",nil,nil,special);return snap.Ok end)
	local expectedRisk=FeedConfig.ExplosionChance[21]*(1-Food.Types[special].Reduction)
	check(math.abs(snap.Risk-expectedRisk)<1e-9 and snap.Cost==1,"Only food reduces base risk; one serving per Feed")
	profile.FeedPlateLevel=10
	-- The live client also polls Snapshot; wait out that shared throttle.
	local maxPlate
	waitFor(function()
		maxPlate=Feed.HandleRequest(a,"Snapshot",nil,nil,special)
		assert(maxPlate.Ok or maxPlate.Code=="Cooldown","Unexpected snapshot failure: "..tostring(maxPlate.Code))
		return maxPlate.Ok
	end)
	check(maxPlate.Ok and maxPlate.Risk==snap.Risk and maxPlate.PlateReduction==nil,"Legacy plate level grants no risk reduction")
	check(not workspace:FindFirstChild("FeedPlateUpgradeSigns"),"Upgrade signs removed; feed plate remains")
	check(not game.ReplicatedStorage:FindFirstChild("FeedPlateUpgradeChanged"),"No upgrade runtime event")
	assert(Overrides.Arm(a,pet.PetId,"Explosion"))
	local oldCount=Food.Count(profile,special)
	local result=Feed.HandleRequest(a,"Feed",pet.PetId,1,special)
	check(result.Accepted and result.Code=="Explosion" and Food.Count(profile,special)==oldCount-1,"Failure consumes selected food exactly once")
	check(Feed.HandleRequest(a,"Feed",pet.PetId,1,special).AttemptId==result.AttemptId and Food.Count(profile,special)==oldCount-1,"Duplicate Feed cannot consume again")
	check(profile.PendingRecovery[pet.PetId] and not profile.Inventory[pet.PetId],"Pending choice quarantines the only pet identity")
	waitFor(function() return not Locks.IsLocked(a) end)
	check(not Rescue.HandleRequest(b,"Revive",pet.PetId,result.AttemptId).Ok,"Foreign Rescue rejected")
	local rescued=Rescue.HandleRequest(a,"Revive",pet.PetId,result.AttemptId)
	check(rescued.Ok and profile.Inventory[pet.PetId].FeedLevel==20,"Immediate Rescue restores pre-failure level")
	check(profile.Inventory[pet.PetId].Variant=="Rainbow","Rescue preserves rare variant")
	check(profile.Inventory[pet.PetId].Locked and Food.Count(profile,special)==oldCount-1,"Rescue preserves lock and does not refund food")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(not Rescue.HandleRequest(a,"Revive",pet.PetId,result.AttemptId).Ok,"Consumed Rescue cannot replay")
	assert(Plate.Place(a,pet.PetId));assert(Overrides.Arm(a,pet.PetId,"Explosion"))
	local expired=Feed.HandleRequest(a,"Feed",pet.PetId,2,"basic")
	check(expired.Accepted,"Second failure creates a new offer")
	local recordedTime=profile.PendingRecovery[pet.PetId].ExplodedAt
	local copy=assert(Schema.Migrate(profile))
	check(copy.PendingRecovery[pet.PetId].ExplodedAt==recordedTime,"Snapshot preserves original expiry anchor")
	waitFor(function() return profile.PendingRecovery[pet.PetId]==nil end,30)
	check(profile.Inventory[pet.PetId].FeedLevel==0 and profile.Inventory[pet.PetId].PetId==pet.PetId,"Automatic timeout returns original pet at level zero")
	check(profile.Inventory[pet.PetId].Variant=="Rainbow","Base-level reset preserves rare variant")
	task.wait(.3)
	check(not Rescue.HandleRequest(a,"Revive",pet.PetId,expired.AttemptId).Ok,"Expired Rescue cannot restore growth")
	check(Schema.Validate(profile),"Final profile validates")
	check(game.StarterGui.MerchantUI:FindFirstChild("TokenHUD")==nil,"No Token HUD asset")
	check(game.StarterGui.FeedYourPetUI.FeedPanel:FindFirstChild("FoodCards")~=nil,"Authored food cards")
	check(game.ReplicatedStorage:FindFirstChild("Farm")==nil,"AFK farm runtime disabled")
	waitFor(function() return reports[a] and reports[b] end,20)
	for _,player in {a,b} do
		check(reports[player].Passed,"Client UI startup: "..player.Name.." "..tostring(reports[player].Failure or ""))
	end
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
