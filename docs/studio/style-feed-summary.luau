assert(not game:GetService("RunService"):IsRunning(), "Edit mode only")
local panel=game.StarterGui.FeedYourPetUI.FeedPanel
local function label(name,y,height,textSize)
	local text=panel[name]
	text.Position=UDim2.fromOffset(24,y)
	text.Size=UDim2.fromOffset(512,height)
	text.TextSize=textSize
	text.TextXAlignment=Enum.TextXAlignment.Center
	text.TextYAlignment=Enum.TextYAlignment.Center
	return text
end
local name=label("PetName",278,50,36)
name.TextScaled=true
local constraint=name:FindFirstChildOfClass("UITextSizeConstraint")
if not constraint then constraint=Instance.new("UITextSizeConstraint");constraint.Parent=name end
constraint.MinTextSize=18;constraint.MaxTextSize=36
label("PetDetails",340,36,26).Text="Common  •  Lv. 0"
label("Notice",400,44,28).Text="EXPLOSION RISK: 0%"
panel.Food.Text="";panel.Food.Visible=false
return "Larger pet summary; duplicate food/cost and explanatory copy removed; risk and button cost retained"
