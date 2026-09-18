if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="FarmUpgradeVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local players=game:GetService("Players")
	local data=require(script.Parent.Services.DataService)
	local plots=require(script.Parent.Services.PlotService)
	local farm=require(script.Parent.Services.FarmService)
	local upgrades=require(script.Parent.Services.FarmUpgradeService)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.FarmConfig)
	assert(adapter.IsMemory(),"Disposable memory data only")
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(predicate)
		local deadline=os.clock()+120
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Verification timed out")
	end
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b)
		and a.Character and a.Character:FindFirstChild("HumanoidRootPart") and game.ReplicatedStorage:FindFirstChild("FarmUpgrade") end)
	local own,other=plots.GetPlot(a),plots.GetPlot(b)
	local sign=workspace.FarmUpgradeSigns[own.Name]
	local profile=data.GetData(a)
	local root=a.Character.HumanoidRootPart;root:SetNetworkOwner(nil)
	local function near() root.CFrame=sign.Board.CFrame+sign.Board.CFrame.ZVector*5 end
	local function request(name,level)
		task.wait(.55)
		return upgrades.HandleRequest(a,name,level)
	end
	upgrades.RefreshSigns()
	check(#workspace.FarmUpgradeSigns:GetChildren()==6,"Six static sign models")
	check(sign:GetAttribute("OwnerUserId")==a.UserId and sign:GetAttribute("Level")==1,"Sign binds owner's level")
	check(sign:GetAttribute("Rate")==2 and sign:GetAttribute("NextRate")==6 and sign:GetAttribute("Cost")==20000,"Sign shows configured current/next output and price")
	check(not upgrades.HandleRequest(a,{},1).Ok,"Malformed plot rejected")
	check(not upgrades.HandleRequest(a,own.Name,0/0).Ok,"NaN level rejected")
	check(not upgrades.HandleRequest(a,own.Name,math.huge).Ok,"Infinite level rejected")
	profile.Money=100000
	check(request(other.Name,1).Code=="NotOwner","Foreign plot rejected")
	root.CFrame=sign.Board.CFrame+Vector3.new(0,0,50)
	check(request(own.Name,1).Code=="TooFar" and profile.FarmLevel==1,"Distant purchase rejected")
	near();profile.Money=19999
	check(request(own.Name,1).Code=="NotEnoughMoney" and profile.Money==19999,"Insufficient Money preserved")
	profile.Money=20000
	local beforeFood=profile.Food
	local result=request(own.Name,1)
	check(result.Ok and result.Code=="Upgraded" and profile.FarmLevel==2 and profile.Money==0,"First purchase deducts exactly 20K and advances one level")
	check(result.Rate==6 and farm.GetRate(a)==6 and profile.FarmPower==1,"Production rises to 6 without changing FarmPower")
	check(result.Money==0 and result.MoneyAt~=nil,"Authoritative HUD balance returned")
	check(not upgrades.HandleRequest(a,own.Name,2).Ok,"Rapid repeat rejected")
	waitFor(function() return not upgrades.GetState(a).Saving end)
	profile.Money=1000000
	check(request(own.Name,1).Code=="LevelChanged" and profile.Money==1000000 and profile.FarmLevel==2,"Stale duplicate cannot buy next level")
	check(request(own.Name,4).Code=="LevelChanged","Skipping levels rejected")
	task.wait(1.1)
	check(profile.Food==beforeFood,"Upgrade does not create passive Food")
	profile.FarmPower=2
	root.CFrame=own.Farm.WorkPoint.CFrame+Vector3.new(0,3,0)
	if not farm.IsFarming(a) then assert(farm.Enter(a)) end
	local beforeMoney=profile.Money
	result=request(own.Name,2)
	check(result.Ok and profile.Money==beforeMoney-500000 and profile.FarmLevel==3,"Owner can upgrade while actively farming")
	check(farm.IsFarming(a) and result.Rate==36,"FarmPower retained and new production immediately active")
	local oldFood=profile.Food
	waitFor(function() return profile.Food>oldFood end)
	check(profile.Food==oldFood+36,"Next active farm tick uses upgraded rate")
	farm.Exit(a,true)
	waitFor(function() return not upgrades.GetState(a).Saving end)
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local reloaded=assert(schema.Migrate(record.Data))
	check(read and reloaded.FarmLevel==3 and reloaded.FarmPower==2 and reloaded.Money==profile.Money,"Money and farm upgrade persist in one profile save/reload")
	profile.FarmLevel=9;profile.FarmPower=1;profile.Money=config.UpgradeCost[10]
	near();result=request(own.Name,9)
	check(result.Ok and profile.FarmLevel==10 and profile.Money==0 and result.Rate==30000,"Final configured upgrade charges 1Qa and reaches level 10")
	waitFor(function() return not upgrades.GetState(a).Saving end)
	check(request(own.Name,10).Code=="MaxLevel" and profile.FarmLevel==10,"Maximum level cannot spend or advance")
	upgrades.RefreshSigns()
	check(sign:GetAttribute("MaxLevel") and sign:GetAttribute("Cost")==nil,"Max sign clears next price")
	check(#config.FoodPerSecond==10 and config.UpgradeCost[11]==nil,"Only ten farm levels are configured")
	profile.FarmLevel=15;profile.FarmPower=2
	local legacy=upgrades.GetState(a)
	check(legacy.Level==10 and legacy.MaxLevel and legacy.Rate==60000 and profile.FarmLevel==15,"Retired-level save uses capped display/rate without destroying progress")
	check(request(own.Name,10).Code=="MaxLevel","Retired-level save cannot buy beyond cap")
	profile.FarmPower=1
	profile.FarmLevel=3;profile.Money=500000
	a.Character.Humanoid.Health=0
	check(not request(own.Name,3).Ok and profile.Money==500000,"Dead character cannot upgrade")
	local oldCharacter=a.Character
	a:LoadCharacterAsync()
	waitFor(function() return a.Character~=oldCharacter and a.Character and a.Character:FindFirstChild("HumanoidRootPart") end)
	check(profile.FarmLevel==3 and profile.FarmPower==1,"Respawn preserves farm progression")
	local otherName=other.Name
	b:Kick("Farm upgrade verification cleanup")
	waitFor(function() return plots.GetPlot(b)==nil end)
	upgrades.RefreshSigns()
	local vacant=workspace.FarmUpgradeSigns[otherName]
	check(vacant:GetAttribute("OwnerUserId")==0 and vacant:GetAttribute("Level")==nil and not vacant:GetAttribute("CanAfford"),"Leaving clears sign ownership and purchase state")
	check(schema.Validate(profile),"Final schema valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
