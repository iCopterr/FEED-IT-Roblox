-- Index anchors the row. Align rendered centers across different ScreenGuis;
-- the Inventory HUD has its own offset, so equal UDim2 values are not enough.
local Layout=require(script.Parent.DeviceLayout)
local Input=game:GetService("UserInputService")
local Collection={}
function Collection.Bind(index,inventory,shop,viewport)
	local connections={}
	local aligning=false
	local function align()
		if aligning or not index.Parent or not inventory.Parent or not shop.Parent then return end
		aligning=true
		local left=index.AbsolutePosition
		local indexSize,inventorySize,shopSize=index.AbsoluteSize,inventory.AbsoluteSize,shop.AbsoluteSize
		local scale=Layout.LeftLauncherScale(viewport.AbsoluteSize,Input.TouchEnabled)
		local gap=Layout.LeftLauncherGap(viewport.AbsoluteSize,Input.TouchEnabled)*scale
		local inventoryLeft=left.X+indexSize.X+gap
		local centerY=left.Y+indexSize.Y/2
		local origin=inventory.Parent.AbsolutePosition
		inventory.Position=UDim2.fromOffset(inventoryLeft-origin.X+inventorySize.X*inventory.AnchorPoint.X,
			centerY-origin.Y+inventorySize.Y*(inventory.AnchorPoint.Y-.5))
		local rowCenter=(left.X+inventoryLeft+inventorySize.X)/2
		local _,shopOffset=Layout.ShopLauncherOffset(viewport.AbsoluteSize,Input.TouchEnabled)
		local shopOrigin=shop.Parent.AbsolutePosition
		shop.Position=UDim2.fromOffset(rowCenter-shopOrigin.X+shopSize.X*(shop.AnchorPoint.X-.5),
			centerY+shopOffset*scale-shopOrigin.Y+shopSize.Y*(shop.AnchorPoint.Y-.5))
		aligning=false
	end
	local function watch(object,property)
		table.insert(connections,object:GetPropertyChangedSignal(property):Connect(align))
	end
	watch(index,"AbsolutePosition");watch(index,"AbsoluteSize")
	watch(inventory,"AbsoluteSize");watch(shop,"AbsoluteSize")
	watch(inventory.Parent,"AbsolutePosition");watch(shop.Parent,"AbsolutePosition")
	watch(viewport,"AbsoluteSize");watch(Input,"TouchEnabled")
	align()
	return function() for _,connection in connections do connection:Disconnect() end end
end
return Collection
