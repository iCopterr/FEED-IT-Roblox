assert(not game:GetService("RunService"):IsRunning(),"Edit mode only")
local gui=game.StarterGui.FeedYourPetUI
local label=gui:FindFirstChild("Notification")
for _,child in gui:GetChildren() do if child.Name=="Notification" and child~=label then child:Destroy() end end
if not label then label=gui.FeedBanner:Clone();label.Name="Notification";label.Parent=gui end
label.BackgroundTransparency=1;label.BorderSizePixel=0;label.Visible=false;label.Text=""
label.AnchorPoint=Vector2.new(.5,1);label.Position=UDim2.new(.5,0,1,-110)
label.Size=UDim2.fromOffset(620,76);label.TextSize=26;label.TextWrapped=true;label.TextScaled=true
label.ZIndex=100
local textStyle=gui.HUD.Travel.Base.ButtonText
label.FontFace=textStyle.FontFace
label.TextStrokeTransparency=textStyle.TextStrokeTransparency
for _,child in label:GetChildren() do
	if child:IsA("UIStroke") then child:Destroy()
	elseif child:IsA("GuiObject") then child:Destroy()
	elseif child:IsA("UIScale") then child.Scale=1 end
end
local outline=assert(textStyle:FindFirstChildOfClass("UIStroke")):Clone()
outline.Name="NotificationOutline";outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;outline.Parent=label
local limit=label:FindFirstChildOfClass("UITextSizeConstraint")
if not limit then limit=Instance.new("UITextSizeConstraint");limit.Parent=label end
limit.MinTextSize=14;limit.MaxTextSize=26
gui.FeedBanner.Visible=false
return "Authored transparent notification text above hotbar"
