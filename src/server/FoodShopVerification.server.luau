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
	-- This regression exercises an existing player, not first-time onboarding.
	profile.Settings.TutorialStep=nil
	local root=a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil);root.Anchored=true
	root.CFrame=workspace.MysteryMerchant.InteractionPoint.CFrame+Vector3.new(0,3,0)
	profile.Money=1e9
	local restock=MerchantConfig.GetRestockId(os.time())
	local stock=MerchantConfig.GetStock(restock)
	check(MerchantConfig.RestockSeconds==5*60,"Merchant restocks every five minutes")
	check(stock[1]=="basic" and stock[2]~=stock[3],"Basic plus two distinct special offers")
	check(#Food.Order==8 and Food.Types.fresh.Reduction==.08 and Food.Types.fortified.Reduction==.22
		and Food.Types.enchanted.Reduction==.38,"Eight ordered food types use configured risk tiers")
	for _,id in MerchantConfig.ItemOrder do check(MerchantConfig.Items[id].Amount==1,"Single item per purchase: "..id) end
	local seen={}
	for id=restock,restock+10000 do
		local sample=MerchantConfig.GetStock(id)
		for index=2,#sample do seen[sample[index]]=(seen[sample[index]] or 0)+1 end
	end
	for _,id in MerchantConfig.ItemOrder do if id~="basic" then check(seen[id],id.." appears in deterministic restocks") end end
	check(seen.revive<100 and seen.blessed<100 and seen.blessed<seen.royal,"Rare items appear in under 1% of sampled five-minute restocks")
	for id,price in {basic=100,fresh=1950,hearty=9750,fortified=39000,gourmet=195000,enchanted=975000,royal=3900000,revive=15000000,blessed=65000000} do
		check(MerchantConfig.Items[id].Price==price,"Approved merchant Money price: "..id)
	end
	local legacy=Schema.CreateDefault();legacy.DataVersion=9;legacy.ReviveCharges=nil
	legacy.Money=12345;legacy.Food=25;legacy.Foods={royal=2};legacy.Settings={}
	local migrated=assert(Schema.Migrate(legacy))
	check(migrated.DataVersion==Schema.CURRENT_VERSION and migrated.ReviveCharges==0 and migrated.ReviveShards==0 and migrated.Money==12345
		and migrated.Food==25 and migrated.Foods.royal==2 and migrated.Settings.TutorialStep==nil,"v9 migration preserves purchased balances without grants or tutorial enrollment")
	local bad=Schema.CreateDefault();bad.ReviveCharges=-1
	check(not Schema.Validate(bad),"Negative charm inventory rejected")
	bad.ReviveCharges=.5;check(not Schema.Validate(bad),"Fractional charm inventory rejected")
	bad=Schema.CreateDefault();bad.ReviveShards=-1
	check(not Schema.Validate(bad),"Negative shard inventory rejected")
	bad.ReviveShards=.5;check(not Schema.Validate(bad),"Fractional shard inventory rejected")
	local purchase=Merchant.HandleRequest(a,"Purchase",1,restock,1)
	check(purchase.Ok and purchase.Remaining==4 and profile.Food==1 and profile.Money==1e9-100,"Basic purchase uses Money and grants one serving")
	check(Merchant.HandleRequest(a,"Purchase",1,restock,1).Ok and profile.Food==1,"Duplicate purchase never charges twice")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",1,restock,2).Ok and profile.Food==2,"Basic remains available within stock")
	for sequence=3,5 do
		waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
		local more=Merchant.HandleRequest(a,"Purchase",1,restock,sequence)
		check(more.Ok and more.Remaining==5-sequence and profile.Food==sequence,"Basic stock purchase "..sequence)
	end
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",1,restock,6).Code=="Sold" and profile.Food==5,"Basic is limited to five servings per restock")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	local shop
	waitFor(function() shop=Merchant.HandleRequest(a,"Snapshot");return shop.Ok end)
	check(shop.Items[1].Purchased and shop.Items[1].Remaining==0 and shop.Items[1].StockLimit==5,"Basic sold-out state is public to its owner")
	for _,offer in shop.Items do
		check(offer.Amount==MerchantConfig.Items[offer.ItemId].Amount,"Shop publishes configured quantity: "..offer.ItemId)
	end
	task.wait(.3)
	check(Merchant.HandleRequest(a,"Purchase",2,restock,6).Ok,"Special food purchase")
	local special=stock[2]
	check((if special=="revive" then profile.ReviveCharges else Food.Count(profile,special))==1,"Correct special item granted")
	-- Feed regression always uses a normal risk-bearing food, independently of stock RNG.
	local feedFood="royal";Food.Add(profile,feedFood,1)
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
	special=feedFood
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
	check(profile.Inventory[pet.PetId].Broken and not profile.PendingRecovery[pet.PetId],"Broken pet remains usable in inventory")
	waitFor(function() return not Locks.IsLocked(a) end)
	check(not Rescue.HandleRequest(b,"Revive",pet.PetId,result.AttemptId).Ok,"Foreign Rescue rejected")
	root.CFrame=workspace.ReviveMachine.InteractionPoint.CFrame+Vector3.new(0,3,0)
	profile.ReviveCharges=0
	check(Rescue.HandleRequest(a,"Revive",pet.PetId,result.AttemptId).Code=="NoRevive" and profile.Inventory[pet.PetId].Broken,"No charm cannot repair damage")
	task.wait(.3);profile.ReviveCharges=1
	local rescued=Rescue.HandleRequest(a,"Revive",pet.PetId,result.AttemptId)
	check(rescued.Ok and profile.Inventory[pet.PetId].FeedLevel==20 and profile.ReviveCharges==0,"Immediate Rescue restores pre-failure level and consumes one charm")
	check(profile.Inventory[pet.PetId].Variant=="Rainbow","Rescue preserves rare variant")
	check(profile.Inventory[pet.PetId].Locked and Food.Count(profile,special)==oldCount-1,"Rescue preserves lock and does not refund food")
	waitFor(function() return not Locks.IsLocked(a) end);task.wait(.3)
	check(not Rescue.HandleRequest(a,"Revive",pet.PetId,result.AttemptId).Ok,"Consumed Rescue cannot replay")
	root.CFrame=CFrame.new(dish.Position+Vector3.new(0,3,6))
	assert(Plate.GetPetId(a)==pet.PetId);assert(Overrides.Arm(a,pet.PetId,"Explosion"))
	local expired=Feed.HandleRequest(a,"Feed",pet.PetId,2,"basic")
	profile.ReviveCharges=1
	check(expired.Accepted,"Second failure creates a new offer")
	local copy=assert(Schema.Migrate(profile))
	check(copy.Inventory[pet.PetId].Broken and copy.Inventory[pet.PetId].BreakId==expired.AttemptId,"Snapshot preserves permanent damage")
	waitFor(function() return not Locks.IsLocked(a) end)
	check(profile.Inventory[pet.PetId].FeedLevel==20 and profile.Inventory[pet.PetId].Variant=="Rainbow","Break preserves level and variant")
	check(profile.ReviveCharges==1,"Broken state never auto-consumes charm")
	check(Rescue.HandleRequest(a,"KeepBase",pet.PetId,expired.AttemptId).Code=="InvalidRequest","Legacy reset action removed")
	profile.Inventory[pet.PetId].FeedLevel=39
	assert(Plate.GetPetId(a)==pet.PetId)
	check(Feed.HandleRequest(a,"Feed",pet.PetId,3,"blessed").Code=="NotEnoughFood","Unowned guaranteed food cannot be used")
	task.wait(FeedConfig.CooldownSeconds+.1)
	check(Feed.HandleRequest(a,"Feed",pet.PetId,3,"revive").Code=="InvalidFood" and profile.ReviveCharges==1,"Charm is not feed food")
	task.wait(FeedConfig.CooldownSeconds+.1)
	Food.Add(profile,"blessed",2)
	assert(Overrides.Arm(a,pet.PetId,"Explosion"))
	local guaranteed=Feed.HandleRequest(a,"Feed",pet.PetId,3,"blessed")
	check(guaranteed.Accepted and guaranteed.Code=="Success" and guaranteed.AppliedRisk==0
		and guaranteed.FeedLevel==40 and Food.Count(profile,"blessed")==1,"Blessed food guarantees success even with forced failure, consumes one and caps at 40")
	check(Feed.HandleRequest(a,"Feed",pet.PetId,3,"blessed").AttemptId==guaranteed.AttemptId
		and Food.Count(profile,"blessed")==1,"Guaranteed feed replay consumes no extra food")
	waitFor(function() return not Locks.IsLocked(a) end)
	check(Feed.HandleRequest(a,"Feed",pet.PetId,4,"blessed").Code=="MaxLevel"
		and Food.Count(profile,"blessed")==1,"Max level does not waste guaranteed food")
	check(Data.Save(a),"Rare consumables save with the profile")
	local persisted=assert(Schema.Migrate(profile))
	check(persisted.ReviveCharges==1 and persisted.Foods.blessed==1,"Rare consumable counts survive save-format round trip")
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
