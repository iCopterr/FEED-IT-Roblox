-- Reuses the owner's notification typography; no modal, blur or input capture.
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local Notice=require(script.Parent.Notifications)
local Popup={}
local current

local function show(gui,text,color,seconds)
	if not gui then return end
	local template=gui:FindFirstChild("Notification")
	if not template then return end
	if current then current:Destroy() end
	Notice.Position(gui)
	template.Visible=false
	local label=template:Clone();current=label
	label.Name="CriticalPopup";label.BackgroundTransparency=1;label.Visible=true;label.Active=false
	label.AnchorPoint=Vector2.new(.5,1);label.Position=template.Position
	label.Size=UDim2.new(template.Size.X.Scale,template.Size.X.Offset,0,110)
	label.TextColor3=color;label.TextTransparency=0
	label.TextScaled=true;label.ZIndex=100
	label.Text=text
	-- Remove copied layout/animation constraints while retaining the authored font/stroke.
	for _,child in label:GetChildren() do
		if child:IsA("UIScale") or child:IsA("UITextSizeConstraint") or child:IsA("UIGradient") then child:Destroy() end
	end
	local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=40;limit.MinTextSize=10;limit.Parent=label
	local scale=Instance.new("UIScale");scale.Scale=.55;scale.Parent=label
	local gradient=Instance.new("UIGradient")
	gradient.Color=ColorSequence.new(Color3.new(1,1,1),color);gradient.Rotation=90;gradient.Parent=label
	label.Rotation=-5;label.Parent=gui
	TweenService:Create(scale,TweenInfo.new(.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
	TweenService:Create(label,TweenInfo.new(.4,Enum.EasingStyle.Quad),{Rotation=0}):Play()
	game:GetService("Debris"):AddItem(label,seconds+.5)
	task.delay(seconds,function()
		if not label.Parent then return end
		TweenService:Create(label,TweenInfo.new(.3),{TextTransparency=1,TextStrokeTransparency=1}):Play()
		for _,child in label:GetChildren() do if child:IsA("UIStroke") then TweenService:Create(child,TweenInfo.new(.3),{Transparency=1}):Play() end end
	end)
end

function Popup.Show(gui,result)
	if result.Code~="Success" or result.Critical~="Critical" then return end
	local text=string.format("CRITICAL!\n+%d LEVEL%s  •  Lv.%d → Lv.%d",result.Gain,if result.Gain==1 then "" else "S",result.OldLevel,result.FeedLevel)
	if result.Gain<2 then text..="  (MAX)" end
	show(gui,text,Color3.fromRGB(255,223,70),Config.Presentation.Critical.BannerSeconds)
end

function Popup.ShowVariant(gui,result,color)
	local variants=require(game.ReplicatedStorage.Shared.Config.VariantConfig)
	if not variants.Types[result.Variant] or result.Variant=="Normal" then return end
	show(gui,string.upper(result.Variant).." HATCH!\n"..(result.PetName or result.SpeciesId).." • ×"..variants.Multiplier(result.Variant).." INCOME",color,3)
end

return Popup
