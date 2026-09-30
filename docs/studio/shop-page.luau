-- One-time edit-mode authoring; never generated during gameplay.
assert(not game:GetService("RunService"):IsRunning())
local sg=game.StarterGui
local existing=sg:FindFirstChild("ShopUI")
if existing then return "ShopUI already authored; preserve owner edits" end
local gui=Instance.new("ScreenGui");gui.Name="ShopUI";gui.ResetOnSpawn=false
gui.IgnoreGuiInset=sg.IndexUI.IgnoreGuiInset;gui.DisplayOrder=sg.IndexUI.DisplayOrder
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local open=sg.IndexUI.Open:Clone();open.Parent=gui
open.Position=UDim2.new(0,18,.5,-76);open.Label.Text="SHOP"
open.Icon.Image="rbxassetid://126548654782636"
local panel=sg.IndexUI.Panel:Clone();panel.Parent=gui
for _,o in panel:GetChildren() do
	if o:IsA("GuiObject") and not table.find({"PageTexture","PageHeader","Title","Close"},o.Name) then o:Destroy() end
end
panel.Visible=false;panel.Size=UDim2.fromOffset(880,620)
panel.Title.Text="SHOP";panel.Title.Size=UDim2.new(1,-100,0,50)
panel.Close.Position=UDim2.new(1,-62,0,13)
local list=Instance.new("ScrollingFrame");list.Name="Offers";list.Position=UDim2.fromOffset(18,84)
list.Size=UDim2.new(1,-36,1,-102);list.BackgroundTransparency=1;list.BorderSizePixel=0
list.ScrollBarThickness=6;list.ScrollingDirection=Enum.ScrollingDirection.Y
list.CanvasSize=UDim2.fromOffset(0,800);list.Parent=panel
local template=sg.MerchantUI.Panel.Offers.Slot1.BuyRobux
local function label(parent,name,text,x,y,w,h,size)
	local l=panel.Title:Clone();l.Name=name;l.Text=text;l.Position=UDim2.fromOffset(x,y)
	l.Size=UDim2.fromOffset(w,h);l.TextSize=size;l.TextScaled=false;l.TextWrapped=true
	l.TextXAlignment=Enum.TextXAlignment.Center;l.Parent=parent;return l
end
local function card(name,title,description,index,color)
	local c=Instance.new("Frame");c.Name=name;c.Size=UDim2.fromOffset(398,180)
	c.Position=UDim2.fromOffset(8+((index-1)%2)*416,8+math.floor((index-1)/2)*196)
	c.BackgroundColor3=color;c.BorderSizePixel=0;c.Parent=list
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=c
	local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(16,17,26);stroke.Thickness=3;stroke.Parent=c
	local texture=panel.PageTexture:Clone();texture.Parent=c;texture.Size=UDim2.fromScale(1,1)
	label(c,"Title",title,12,12,374,38,28)
	label(c,"Description",description,16,54,366,60,19)
	local buy=template:Clone();buy.Name="Buy";buy.AnchorPoint=Vector2.zero
	buy.Position=UDim2.fromOffset(16,126);buy.Size=UDim2.new(1,-32,0,40)
	buy.Active=false;buy.AutoButtonColor=false;buy.Parent=c
	return c
end
local a=card("Welcome","WELCOME TREAT PACK","2 Hearty • 1 Royal • 1 Revive Charm\nOnce per player",1,Color3.fromRGB(96,63,115))
a.Buy.ButtonText.Text="9 ROBUX • SOON"
local b=card("DoubleMoney","×2 MONEY","Double pet income\nPermanent",2,Color3.fromRGB(51,100,72))
b.Buy.ButtonText.Text="249 ROBUX • SOON"
local amounts={"25K","100K","300K","1.5M","5M","10M"}
local prices={19,49,99,249,499,799}
for i,amount in amounts do
	local c=card("Money"..i,"$"..amount,"MONEY PACK",i+2,Color3.fromRGB(56,69,85))
	c.Buy.ButtonText.Text=prices[i].." ROBUX • SOON"
end
-- Preserve the exact existing button decoration, but avoid duplicate motion scales.
for _,parent in gui:GetDescendants() do
	local seen={}
	for _,child in parent:GetChildren() do
		if child:IsA("UIScale") then
			if seen[child.Name] then child:Destroy() else seen[child.Name]=true end
		end
	end
end
gui.Parent=sg
return "Authored ShopUI: Index-style launcher, eight offers, disabled purchases"
