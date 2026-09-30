-- Inventory geometry belongs to the authored ScreenGui, including card templates.
-- Fit the whole composition without rewriting its child layout on every refresh.
local Layout={}
function Layout.Apply(gui,_cards,buttons,viewportOverride)
	local modal=gui.Inventory
	local bar=gui.Hotbar
	local viewport=viewportOverride or gui.AbsoluteSize
	local fit=modal:FindFirstChild("InventoryFitScale")
	if fit and viewport.X>0 and viewport.Y>0 then
		local width=modal.Size.X.Scale*viewport.X+modal.Size.X.Offset
		local height=modal.Size.Y.Scale*viewport.Y+modal.Size.Y.Offset
		fit.Scale=math.max(.01,math.min(1,(viewport.X-24)/math.max(1,width),(viewport.Y-24)/math.max(1,height)))
	end
	-- Hotbar slots still flow dynamically; they are independent of the inventory.
	local count=0
	for _,button in buttons do if button.Visible then count+=1 end end
	local columns=math.max(1,math.min(count,math.floor((viewport.X-24)/60)))
	local side=math.min(66,math.floor((viewport.X-24-(columns-1)*8)/columns))
	local rows=math.ceil(count/columns)
	bar.Size=UDim2.fromOffset(if count==0 then 0 else columns*(side+8)-8,if count==0 then 0 else rows*(side+8)-8)
	local index=0
	for _,button in buttons do
		if button.Visible then
			button.Position=UDim2.fromOffset((index%columns)*(side+8),math.floor(index/columns)*(side+8))
			index+=1
		end
		button.Size=UDim2.fromOffset(side,side)
		button.Preview.Size=UDim2.fromOffset(side-4,side-18)
		button.ItemName.Position=UDim2.new(0,3,1,-22);button.ItemName.Size=UDim2.new(1,-6,0,20);button.ItemName.TextSize=if side<50 then 9 else 11
		button.State.Visible=false;button.State.Position=UDim2.new(1,-38,0,3)
	end
	bar.Hint.Size=UDim2.fromOffset(320,26)
	bar.Hint.AnchorPoint=Vector2.new(.5,0)
	bar.Hint.Position=UDim2.new(.5,0,0,-32)
end
return Layout
