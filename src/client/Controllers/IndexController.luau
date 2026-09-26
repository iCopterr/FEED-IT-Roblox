local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Eggs=require(ReplicatedStorage.Shared.Config.EggConfig)
local View=require(script.Parent.Parent.UI.IndexView)
local Motion=require(script.Parent.Parent.UI.Motion)
local Controller={}

function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=assert(playerGui:WaitForChild("IndexUI",30),"IndexUI missing; check Rojo")
	local panel=gui.Panel
	local remote=ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
	local eggId=Eggs.Order[1]
	local speciesId=Eggs.Definitions[eggId].Results[1].SpeciesId
	local discovered={}
	local busy=false
	local otherPanels={}
	local function render()
		if panel.Visible then View.Render(panel,discovered,eggId,speciesId) end
	end
	local function refresh()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("IndexSnapshot") end)
		busy=false
		if ok and result.Ok then
			discovered=result.PetIndex;panel.Status.Text="";render()
		elseif not ok or result.Code~="Cooldown" then
			panel.Status.Text=if ok and result.Code=="Loading" then "Loading discoveries…" else "Unable to refresh. Retrying…"
		end
	end
	function Controller.SelectEgg(id)
		if not Eggs.Definitions[id] then return end
		eggId=id;speciesId=Eggs.Definitions[id].Results[1].SpeciesId
		panel.Pets.CanvasPosition=Vector2.zero
		render()
	end
	function Controller.SelectPet(id)
		for _,entry in Eggs.Definitions[eggId].Results do
			if entry.SpeciesId==id then speciesId=id;render();return end
		end
	end
	function Controller.Open()
		for other in otherPanels do if other.Parent then other.Visible=false end end
		panel.Visible=true;render();task.spawn(refresh)
	end
	gui.Open.Activated:Connect(function()
		if panel.Visible then Motion.Close(panel) else Controller.Open() end
	end)
	panel.Close.Activated:Connect(function() Motion.Close(panel) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		player:SetAttribute("IndexPanelOpen",panel.Visible)
		if not panel.Visible then View.Clear(panel) end
	end)
	player:SetAttribute("IndexPanelOpen",false)
	Input.InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.Escape and panel.Visible then Motion.Close(panel) end
	end)
	for index,id in Eggs.Order do
		panel.Categories["Egg"..index].Activated:Connect(function() Controller.SelectEgg(id) end)
	end
	for index=1,6 do
		local card=panel.Pets["Pet"..index]
		card.Activated:Connect(function() Controller.SelectPet(card:GetAttribute("SpeciesId")) end)
	end
	local function watch(other)
		otherPanels[other]=true
		other:GetPropertyChangedSignal("Visible"):Connect(function()
			if other.Visible then panel.Visible=false end
		end)
	end
	for _,name in {"FeedYourPetUI","MerchantUI","ReviveUI","DebugUI","PenManagerUI"} do
		task.spawn(function()
			local other=playerGui:WaitForChild(name,30)
			if not other then return end
			if name=="FeedYourPetUI" then watch(other.Inventory);watch(other.FeedPanel)
			elseif name=="PenManagerUI" then
				for _,child in other:GetChildren() do if child:IsA("Frame") and child.Name~="Dock" then watch(child) end end
			else watch(other.Panel) end
		end)
	end
	Motion.BindPopup(panel)
	for _,object in panel:GetDescendants() do
		if object:IsA("GuiButton") then Motion.BindButton(object,panel) end
	end
	Motion.BindButton(gui.Open,gui.Open)
	local function resize()
		local size=gui.AbsoluteSize
		panel.UIScale.Scale=math.max(.1,math.min(1,(size.X-24)/1020,(size.Y-24)/600))
		gui.Open.UIScale.Scale=if size.X<760 then .7 else math.min(1,size.Y/650)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
	task.spawn(function()
		while gui.Parent do
			if panel.Visible then refresh() end
			task.wait(2)
		end
	end)
	return gui
end

return Controller
