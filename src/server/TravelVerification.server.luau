if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="TravelVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local data=require(services.DataService)
	local travel=require(services.TravelService)
	local plots=require(services.PlotService)
	local locks=require(services.FeedLocks)
	assert(require(script.Parent.Data.DataStoreAdapter).IsMemory())
	local function check(v,n) assert(v,n);table.insert(checks,n) end
	local deadline=os.clock()+75
	local players
	repeat players=game.Players:GetPlayers();task.wait(.1) until (#players==2 and data.IsLoaded(players[1]) and data.IsLoaded(players[2]) and players[1].Character and players[2].Character) or os.clock()>deadline
	assert(#players==2)
	for _,p in players do
		local root=p.Character:WaitForChild("HumanoidRootPart",10)
		root.Anchored=false
		local money=data.GetData(p).Money
		check(travel.HandleRequest(p,{}).Code=="InvalidDestination","Reject client coordinate/table")
		check(travel.HandleRequest(p,"OtherPlot").Code=="InvalidDestination","Reject arbitrary destination")
		check(travel.HandleRequest(p,"Base").Ok,"Base request succeeds")
		check((p.Character:GetPivot().Position-plots.GetPlot(p).Spawn.Position).Magnitude<8,"Own plot only")
		check(travel.HandleRequest(p,"Merchant").Code=="Cooldown","Spam throttled")
		task.wait(.15)
		check(travel.HandleRequest(p,"Merchant").Ok,"Merchant request succeeds")
		check((p.Character:GetPivot().Position-workspace.MysteryMerchant.InteractionPoint.Position).Magnitude<8,"Arrives at merchant interaction area")
		task.wait(.15)
		assert(locks.Begin(p,"TravelTest"))
		local before=p.Character:GetPivot()
		check(travel.HandleRequest(p,"Base").Code=="Busy" and p.Character:GetPivot()==before,"Saving transaction blocks teleport")
		locks.Finish(p)
		check(data.GetData(p).Money==money,"Travel does not charge currency")
	end
	local h=game.StarterGui.FeedYourPetUI.HUD
	local count=0;for _,c in h:GetChildren() do if c.Name=="Travel" then count+=1 end end
	check(count==1,"Single authored travel row")
	for _,name in {"Base","Merchant"} do
		check(h.Travel[name]:IsA("ImageButton") and h.Travel[name].Image==h.OpenInventory.Texture.Image,"Matching stud button "..name)
		check(h.Travel[name].Size.X.Offset>h.OpenInventory.Size.X.Offset and h.Travel[name].Size.Y.Offset>h.OpenInventory.Size.Y.Offset,"Larger travel button "..name)
	end
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else failure})
