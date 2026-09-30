assert(not game:GetService("RunService"):IsRunning(),"Edit mode only")
local merchant=game.StarterGui.MerchantUI.Panel
local pen=game.StarterGui.PenManagerUI.Panel
local template=merchant.Offers.Slot1.BuyRobux
local function button(parent,name,text,position,size)
	local b=parent:FindFirstChild(name)
	for _,child in parent:GetChildren() do if child.Name==name and child~=b then child:Destroy() end end
	if not b then b=template:Clone();b.Name=name;b.Parent=parent end
	b.AnchorPoint=Vector2.zero;b.Position=position;b.Size=size
	b.ButtonText.Text=text;b.ButtonText.TextScaled=true
	b.Active=false;b.AutoButtonColor=false;b.Selectable=false
	b:SetAttribute("SuppressClickSound",true)
	return b
end
button(merchant,"RestockBuy","RESTOCK • 39 ROBUX • SOON",UDim2.new(0,16,1,-50),UDim2.new(1,-32,0,36))
merchant.Offers.Size=UDim2.new(1,-32,0,298)
merchant.Status.Visible=false
local grow=button(pen,"GrowAll","GROW ALL • UP TO 199 ROBUX • SOON",pen.EquipBest.Position,pen.EquipBest.Size)
grow.Visible=false
pen.List.Size=UDim2.new(1,-28,1,-202)
return "Authored disabled Grow All and Restock; no purchase/reward handlers"
