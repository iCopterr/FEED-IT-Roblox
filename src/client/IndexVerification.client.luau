if not game:GetService("RunService"):IsStudio() then return end
local storage=game:GetService("ReplicatedStorage")
local deadline=os.clock()+30
local report
repeat report=storage:FindFirstChild("IndexVerificationReport");if report then break end;task.wait(.1) until os.clock()>deadline
if not report then return end
local ok,failure=xpcall(function()
	local player=game.Players.LocalPlayer
	local gui=player.PlayerGui:WaitForChild("IndexUI",10)
	local panel=gui.Panel
	local controller=require(script.Parent.Controllers.IndexController)
	local view=require(script.Parent.UI.IndexView)
	local eggs=require(storage.Shared.Config.EggConfig)
	local pets=require(storage.Shared.Config.PetConfig)
	local number=require(storage.Shared.NumberFormat).Money
	local untilReady=os.clock()+10
	repeat if controller.Open then break end;task.wait(.1) until os.clock()>untilReady
	assert(controller.Open,"Index controller started")
	assert(gui.Open.Position.X.Scale==0 and gui.Open.Position.Y.Scale==.5,"Index button is on the opposite left-middle side")
	local all={};for id in pets.Species do all[id]=true end
	local covered=0
	for index,eggId in eggs.Order do
		local results=eggs.Definitions[eggId].Results
		view.Render(panel,all,eggId,results[1].SpeciesId)
		assert(panel.Categories["Egg"..index].Preview.World:FindFirstChildOfClass("Model"),"Egg category has a model")
		for i,entry in results do
			local card=panel.Pets["Pet"..i]
			local species=pets.Species[entry.SpeciesId]
			assert(card.ItemName.Text==species.DisplayName and card.Rarity.Text==species.Rarity,"Unlocked card identifies species")
			assert(card.Income.Text:find("%%") and card.Income.Text:find("$"..number(species.BaseIncome).."/s",1,true),"Card shows hatch percentage and normal level-zero income")
			local model=assert(card.Preview.World:FindFirstChildOfClass("Model"),"Every pet has a preview")
			for _,object in model:GetDescendants() do
				assert(not object:IsA("JointInstance") and not object:IsA("WeldConstraint") and not object:IsA("Constraint"),"Static previews omit rig joints")
				if object:IsA("BasePart") then
					assert(object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery,"UI geometry is non-interactive")
				end
			end
			assert(card.Preview.ImageColor3==Color3.new(1,1,1),"Unlocked preview uses original colors")
			covered+=1
		end
		view.Render(panel,{},eggId,results[1].SpeciesId)
		for i=1,#results do
			local card=panel.Pets["Pet"..i]
			local species=pets.Species[results[i].SpeciesId]
			assert(card.ItemName.Text==species.DisplayName and card.Rarity.Text==species.Rarity and card.Income.Text:find("%% HATCH"),"Undiscovered card discloses identity, rarity and hatch percentage")
			assert(card.Preview.ImageColor3==Color3.new(0,0,0),"Undiscovered model is a black silhouette")
		end
		assert(panel.Detail.Preview.ImageColor3==Color3.new(0,0,0),"Locked detail is also a silhouette")
		assert(panel.Detail.Level.Text:find("HATCH") and panel.Detail.Source.Text:find("NORMAL") and panel.Detail.Source.Text:find("CELESTIAL"),"Detail discloses selected pet and variant odds")
	end
	assert(covered==36 and #eggs.Order==6,"All thirty-six pets and six eggs covered")
	view.Clear(panel)
	controller.Open()
	controller.SelectEgg("advanced_egg")
	assert(panel.CategoryName.Text=="Advanced Egg","Category switching works")
	controller.SelectPet(eggs.Definitions.advanced_egg.Results[6].SpeciesId)
	assert(panel.Pets.Pet6:GetAttribute("Selected"),"Pet selection works")
	local deadline=os.clock()+10
	repeat task.wait(.1) until panel.Status.Text=="" and panel.Progress.Text~="DISCOVERED  0 / 36" or os.clock()>deadline
	assert(player:GetAttribute("IndexPanelOpen"),"Index signals modal state")
	local main=player.PlayerGui.FeedYourPetUI
	main.Inventory.Visible=true;task.wait(.1)
	assert(not panel.Visible and not player:GetAttribute("IndexPanelOpen"),"Opening inventory closes Index")
	assert(#panel.Detail.Preview.World:GetChildren()==0,"Closing releases preview models")
	assert(panel.Detail.Preview.CurrentCamera==nil and not panel.Detail.Preview:FindFirstChild("PreviewCamera"),"Closing releases preview cameras")
	main.Inventory.Visible=false
	for _,object in gui:GetDescendants() do
		if object:IsA("GuiButton") then assert(not object.Selectable,"Index buttons do not capture WASD navigation") end
	end
end,debug.traceback)
report:FireServer({Passed=ok,Failure=if ok then nil else tostring(failure)})
