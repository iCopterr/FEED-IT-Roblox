assert(not game:GetService("RunService"):IsRunning())
local sg=game.StarterGui
if sg:FindFirstChild("SettingsUI") then return "Preserving existing SettingsUI" end
local gui=Instance.new("ScreenGui");gui.Name="SettingsUI";gui.ResetOnSpawn=false
gui.IgnoreGuiInset=sg.ShopUI.IgnoreGuiInset;gui.DisplayOrder=sg.ShopUI.DisplayOrder
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local open=sg.IndexUI.Open:Clone();open.Position=UDim2.new(0,18,.5,76);open.Label.Text="SETTINGS"
open.Label.TextSize=20;open.Icon.Visible=false;open.Label.Position=UDim2.fromOffset(3,7)
open.Label.Size=UDim2.new(1,-6,0,50);open.Parent=gui
local p=sg.ShopUI.Panel:Clone();p.Parent=gui;p.Size=UDim2.fromOffset(820,610)
p.Title.Text="SETTINGS";p.Title.TextSize=36;p.Visible=false
p.Offers:Destroy()
local function label(parent,name,text,pos,size,fontSize)
	local l=p.Title:Clone();l.Name=name;l.Text=text;l.Position=pos;l.Size=size
	l.TextScaled=false;l.TextSize=fontSize;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=parent
	return l
end
for i,key in {"MusicVolume","SFXVolume","ShowOtherPets","ShowOwnPets"} do
	local row=Instance.new("Frame");row.Name=key;row.Position=UDim2.fromOffset(18,82+(i-1)*124)
	row.Size=UDim2.new(1,-36,0,110);row.BackgroundColor3=Color3.fromRGB(53,66,84);row.BorderSizePixel=0;row.Parent=p
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=row
	local stroke=Instance.new("UIStroke");stroke.Thickness=3;stroke.Color=Color3.fromRGB(17,20,30);stroke.Parent=row
	local texture=p.PageTexture:Clone();texture.Parent=row
	local title=({"Music","SFX","View Other Pets","View Your Pets"})[i]
	label(row,"Title",title,UDim2.fromOffset(16,16),UDim2.fromOffset(360,42),30)
	if i<=2 then
		label(row,"Description",if i==1 then "Background music" else "Sound effects",UDim2.fromOffset(16,61),UDim2.fromOffset(330,30),19)
		local track=Instance.new("TextButton");track.Name="Slider";track.Text="";track.AutoButtonColor=false
		track.Position=UDim2.fromOffset(390,40);track.Size=UDim2.fromOffset(350,28);track.BackgroundColor3=Color3.fromRGB(26,31,43);track.BorderSizePixel=0;track.ZIndex=5;track.Parent=row
		corner:Clone().Parent=track
		local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=Color3.fromRGB(255,224,78);fill.BorderSizePixel=0;fill.ZIndex=6;fill.Parent=track;corner:Clone().Parent=fill
		local knob=Instance.new("Frame");knob.Name="Knob";knob.AnchorPoint=Vector2.new(.5,.5);knob.Position=UDim2.fromScale(1,.5);knob.Size=UDim2.fromOffset(26,42);knob.BackgroundColor3=Color3.fromRGB(255,245,108);knob.ZIndex=7;knob.Parent=track;corner:Clone().Parent=knob
		label(row,"Value","100%",UDim2.fromOffset(620,4),UDim2.fromOffset(125,30),20)
		track:SetAttribute("SuppressClickSound",true)
	else
		local toggle=sg.ShopUI.Panel.Offers.Money1.Buy:Clone();toggle.Name="Toggle"
		toggle.Position=UDim2.fromOffset(555,28);toggle.Size=UDim2.fromOffset(190,54);toggle.Active=true
		toggle.ButtonText.Text="ON";toggle.Parent=row
	end
end
gui.Parent=sg
return "Authored SettingsUI with music/SFX sliders and placed-pet visibility toggles"
