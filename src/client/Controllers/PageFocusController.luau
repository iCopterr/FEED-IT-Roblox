local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local Config=game.ReplicatedStorage.Shared.Config
local Merchant=require(Config.MerchantConfig)
local Carry=require(Config.CarryConfig)
local Revive=require(Config.ReviveConfig)
local Controller={}
local pages={
	FeedYourPetUI={"Inventory","FeedPanel"}, MerchantUI={"Panel"},
	ReviveUI={"Panel"}, DebugUI={"Panel"}, IndexUI={"Panel"},
	-- Egg and pen remote side panels intentionally leave the world view unchanged.
}
local started=false

local function location(player,screen,page)
	if screen=="MerchantUI" then
		local model=workspace:FindFirstChild("MysteryMerchant")
		return model and model:FindFirstChild("InteractionPoint",true),Merchant.PurchaseDistance,true
	elseif screen=="ReviveUI" then
		local model=workspace:FindFirstChild("ReviveMachine")
		return model and model:FindFirstChild("InteractionPoint",true),Revive.MachineDistance,true
	elseif screen=="FeedYourPetUI" and page=="FeedPanel" then
		local plots=workspace:FindFirstChild("PlayerPlots")
		for _,plot in plots and plots:GetChildren() or {} do
			if plot:GetAttribute("OwnerUserId")==player.UserId then
				local plate=plot:FindFirstChild("FeedPlate")
				return plate and plate:FindFirstChild("Dish"),Carry.PlateDistance,true
			end
		end
		return nil,Carry.PlateDistance,true
	end
	return nil,nil,false
end

function Controller.Start()
	if started then return end;started=true
	local player=Players.LocalPlayer
	local gui=player:WaitForChild("PlayerGui")
	-- Local post effect, not UI geometry; leave the map's lighting effects intact.
	local blur=Instance.new("BlurEffect");blur.Name="PageFocusBlur";blur.Size=0;blur.Parent=Lighting
	local camera,baseFov,focused,fovTween,blurTween
	local function cancelFov() if fovTween then fovTween:Cancel();fovTween=nil end end
	local function update()
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local alive=root and humanoid and humanoid.Health>0
		local open=false
		for screenName,names in pages do
			local screen=gui:FindFirstChild(screenName)
			if not screen then continue end
			for _,name in names do
				local panel=screen:FindFirstChild(name)
				if not panel or not panel.Visible then continue end
				local point,distance,localPage=location(player,screenName,name)
				if not alive or (localPage and (not point or not point:IsA("BasePart") or (root.Position-point.Position).Magnitude>distance)) then
					panel.Visible=false
				elseif screen.Enabled then open=true end
			end
		end
		blur:SetAttribute("PageOpen",open)
		if workspace.CurrentCamera~=camera then
			cancelFov()
			if camera and baseFov then camera.FieldOfView=baseFov end
			camera=workspace.CurrentCamera;baseFov=nil;focused=nil
		end
		if focused==open then return end
		-- Keep the original baseline during rapid close/reopen, not an in-flight FOV.
		if open and baseFov==nil and camera then baseFov=camera.FieldOfView end
		focused=open
		cancelFov()
		if camera and baseFov then
			fovTween=TweenService:Create(camera,TweenInfo.new(.22,Enum.EasingStyle.Quad),{
				FieldOfView=if open then math.max(20,baseFov-10) else baseFov})
			fovTween:Play()
			if not open then
				local restoringCamera=camera
				fovTween.Completed:Once(function(state)
					if state==Enum.PlaybackState.Completed and not focused and camera==restoringCamera then baseFov=nil end
				end)
			end
		end
		if blurTween then blurTween:Cancel() end
		blurTween=TweenService:Create(blur,TweenInfo.new(.22,Enum.EasingStyle.Quad),{Size=if open then 18 else 0})
		blurTween:Play()
	end
	task.spawn(function()
		while gui.Parent do update();task.wait(.1) end
		cancelFov();if blurTween then blurTween:Cancel() end
		if camera and baseFov then camera.FieldOfView=baseFov end
		blur:Destroy()
	end)
end
return Controller
