local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Config=require(game.ReplicatedStorage.Shared.Config.SettingsConfig)
local Motion=require(script.Parent.Parent.UI.Motion)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local pg=player:WaitForChild("PlayerGui")
	local gui=pg:WaitForChild("SettingsUI");local p=gui.Panel
	local remote=game.ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
	local values=table.clone(Config.Defaults);local loaded=false
	player:SetAttribute("SettingsPanelOpen",false)
	local music=SoundService:WaitForChild("MusicVolumeGroup")
	local sfx=SoundService:WaitForChild("SFXVolumeGroup")
	local function route(sound)
		if sound:IsA("Sound") then sound.SoundGroup=if sound.Name=="BackgroundMusic" then music else sfx end
	end
	SoundService.DescendantAdded:Connect(route)
	for _,sound in SoundService:GetDescendants() do route(sound) end
	local function render()
		music.Volume=values.MusicVolume;sfx.Volume=values.SFXVolume
		for key,value in values do
			local row=p[key]
			if type(value)=="number" then
				row.Slider.Fill.Size=UDim2.fromScale(value,1);row.Slider.Knob.Position=UDim2.fromScale(value,.5)
				row.Value.Text=math.round(value*100).."%"
			else
				row.Toggle.ButtonText.Text=if value then "ON" else "OFF"
				row.Toggle.BackgroundColor3=if value then Color3.fromRGB(80,220,55) else Color3.fromRGB(235,65,65)
				for _,o in row.Toggle:GetDescendants() do if o:IsA("UIGradient") then
					o.Color=ColorSequence.new(if value then Color3.fromRGB(110,255,70) else Color3.fromRGB(255,90,90),if value then Color3.fromRGB(35,165,30) else Color3.fromRGB(165,35,35))
				end end
			end
		end
	end
	local pending={}
	local function set(key,value)
		if not loaded then return end
		values[key]=value;pending[key]=value;render()
	end
	task.spawn(function()
		while gui.Parent and not loaded do
			local ok,result=pcall(function()return remote:InvokeServer("GetSettings")end)
			if ok and result.Ok then values=Config.Read(result.Settings);loaded=true;render() else task.wait(1) end
		end
		while gui.Parent do
			task.wait(.4)
			local key,value=next(pending)
			if key then
				local ok,result=pcall(function()return remote:InvokeServer("SetSetting",key,value)end)
				if ok and result.Ok and pending[key]==value then pending[key]=nil end
			end
		end
	end)
	local drag,dragInput
	local function slide(x)
		if not drag then return end
		local bar=p[drag].Slider
		set(drag,math.round(math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)*100)/100)
	end
	for _,key in {"MusicVolume","SFXVolume"} do
		p[key].Slider.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=key;dragInput=input;slide(input.Position.X) end
		end)
		p[key].Slider.InputChanged:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseWheel then set(key,math.clamp(values[key]+input.Position.Z*.05,0,1)) end
		end)
	end
	Input.InputChanged:Connect(function(input)
		if drag and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement) then slide(input.Position.X) end
	end)
	Input.InputEnded:Connect(function(input)
		if input==dragInput or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=nil;dragInput=nil end
	end)
	for _,key in {"ShowOwnPets","ShowOtherPets"} do p[key].Toggle.Activated:Connect(function()set(key,not values[key])end);Motion.BindButton(p[key].Toggle,p) end
	local others={}
	for _,name in {"ShopUI","IndexUI","MerchantUI","ReviveUI","DebugUI","FeedYourPetUI","PenManagerUI"} do
		task.spawn(function()
			local screen=pg:WaitForChild(name,30);if not screen then return end
			for _,panel in screen:GetChildren() do
				if panel:IsA("Frame") and table.find({"Panel","Inventory","FeedPanel","GrowNow"},panel.Name) then
					others[panel]=true;panel:GetPropertyChangedSignal("Visible"):Connect(function()if panel.Visible then p.Visible=false end end)
				end
			end
		end)
	end
	gui.Open.Activated:Connect(function()
		if p.Visible then Motion.Close(p) else for other in others do other.Visible=false end;p.Visible=true end
	end)
	p.Close.Activated:Connect(function()Motion.Close(p)end)
	p:GetPropertyChangedSignal("Visible"):Connect(function()player:SetAttribute("SettingsPanelOpen",p.Visible);if not p.Visible then drag=nil end end)
	Input.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape and p.Visible then Motion.Close(p) end end)
	Motion.BindPopup(p);Motion.BindButton(gui.Open,gui.Open);Motion.BindButton(p.Close,p)
	local function resize()
		p.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/820,(gui.AbsoluteSize.Y-24)/610))
		local scale=if gui.AbsoluteSize.X<760 then .7 else math.min(1,gui.AbsoluteSize.Y/650)
		gui.Open.UIScale.Scale=scale;gui.Open.Position=UDim2.new(0,18,.5,76*scale)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();render()
	local originals=setmetatable({},{__mode="k"})
	task.spawn(function()
		local plots=workspace:WaitForChild("PlayerPlots")
		while gui.Parent do
			for _,plot in plots:GetChildren() do
				local pen=plot:FindFirstChild("Pen")
				local folder=pen and pen:FindFirstChild("ActivePets")
				if folder then
					for _,model in folder:GetChildren() do
						local own=model:GetAttribute("OwnerUserId")==player.UserId
						local hidden=not values[if own then "ShowOwnPets" else "ShowOtherPets"]
						for _,o in model:GetDescendants() do
							if o:IsA("BasePart") then o.LocalTransparencyModifier=if hidden then 1 else 0
							elseif o:IsA("BillboardGui") or o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") or o:IsA("Highlight") then
								if hidden then if originals[o]==nil then originals[o]=o.Enabled end;o.Enabled=false
								elseif originals[o]~=nil then o.Enabled=originals[o];originals[o]=nil end
							end
						end
					end
				end
			end
			task.wait(.25)
		end
	end)
end
return Controller
