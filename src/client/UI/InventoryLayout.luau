-- Reflow existing StarterGui objects only; never constructs UI instances.
local Layout={}
function Layout.Apply(gui,cards,buttons,viewportOverride)
	local modal=gui.Inventory
	local layout=modal.Panel.Layout
	local detail=layout.Details
	local bar=gui.Hotbar
	local viewport=viewportOverride or gui.AbsoluteSize
	local narrow=viewport.X<760
	local w=if narrow then math.min(560,viewport.X-24) else math.min(840,viewport.X*.86)
	local h=if narrow then math.min(660,viewport.Y-32) else math.min(560,viewport.Y*.82)
	modal.Size=UDim2.fromOffset(w,h)
	local compact=not narrow and h<420
	local pad=18
	layout.Title.Position=UDim2.fromOffset(pad,12)
	layout.Title.Size=UDim2.fromOffset(w-(if narrow then 80 else 235),38)
	layout.Title.TextSize=if narrow then 24 else 30
	layout.Close.Position=UDim2.new(1,-58,0,12);layout.Close.Size=UDim2.fromOffset(40,40)
	layout.Close.ButtonText.TextSize=26
	layout.PenSlots.Position=UDim2.new(1,-202,0,19);layout.PenSlots.Size=UDim2.fromOffset(134,28)
	layout.PenSlots.TextSize=16;layout.PenSlots.Visible=not narrow
	local toolbarY=62
	layout.Search.Position=UDim2.fromOffset(pad,toolbarY)
	layout.Search.Size=UDim2.fromOffset(if narrow then w-36 else w-476,40)
	layout.Search.TextSize=16
	local tabsY=if narrow then 110 else toolbarY
	local tabsX=if narrow then pad else w-446
	local tabStep=if narrow then math.min(64,(w-162)/3) else 70
	for i,name in {"All","Pet","Egg"} do
		layout[name].Position=UDim2.fromOffset(tabsX+(i-1)*tabStep,tabsY)
		layout[name].Size=UDim2.fromOffset(tabStep-6,40)
		layout[name].ButtonText.TextSize=if narrow then 14 else 17
	end
	layout.Sort.Position=UDim2.new(1,-(if narrow then 134 else 230),0,tabsY)
	layout.Sort.Size=UDim2.fromOffset(if narrow then 116 else 212,40)
	layout.Sort.ButtonText.TextSize=if narrow then 12 else 17
	local top=if narrow then 160 else 116
	local listW=if narrow then w-36 else w-294
	local listH=if narrow then math.max(65,h-top-222) else h-top-42
	layout.Pets.Position=UDim2.fromOffset(pad,top);layout.Pets.Size=UDim2.fromOffset(listW,listH)
	local columns=math.max(2,math.floor((listW-16)/150))
	local cellW=math.floor((listW-20-(columns-1)*10)/columns)
	layout.Pets.Grid.CellSize=UDim2.fromOffset(cellW,174)
	for _,card in cards do
		card.Preview.Size=UDim2.new(1,-12,0,87)
		card.ItemName.Position=UDim2.fromOffset(8,99);card.ItemName.Size=UDim2.new(1,-16,0,32);card.ItemName.TextSize=15
		card.Stats.Position=UDim2.fromOffset(8,132);card.Stats.Size=UDim2.new(1,-16,0,18);card.Stats.TextSize=13
		card.State.Position=UDim2.fromOffset(8,152);card.State.Size=UDim2.new(1,-16,0,16);card.State.TextSize=11
		card.LockMark.Position=UDim2.new(1,-30,0,9)
	end
	layout.EmptyState.Position=UDim2.fromOffset(pad+16,top+math.max(8,(listH-90)/2))
	layout.EmptyState.Size=UDim2.fromOffset(listW-32,90)
	layout.EmptyState.TextSize=if narrow then 19 else 23
	layout.EmptyState.TextXAlignment=Enum.TextXAlignment.Center
	detail.Position=if narrow then UDim2.fromOffset(pad,h-214) else UDim2.new(1,-258,0,top)
	detail.Size=if narrow then UDim2.fromOffset(w-36,176) else UDim2.fromOffset(240,h-top-42)
	local detailH=detail.Size.Y.Offset
	local previewHeight=if narrow or compact then 0 else math.clamp(detailH-240,50,100)
	detail.Preview.Visible=previewHeight>0
	detail.Preview.Position=UDim2.fromOffset(14,8);detail.Preview.Size=UDim2.new(1,-28,0,previewHeight)
	local nameY=if previewHeight>0 then previewHeight+12 else 8
	detail.ItemName.Position=UDim2.fromOffset(14,nameY)
	detail.ItemName.Size=UDim2.new(1,-28,0,if narrow then 28 else 44)
	detail.ItemName.TextSize=if narrow then 18 else 22
	detail.ItemName.TextXAlignment=Enum.TextXAlignment.Center
	local statsY=nameY+(if narrow then 32 else 48)
	local singleRow=narrow or compact
	local buttonsTop=detailH-(if singleRow then 56 else 106)
	detail.Stats.Position=UDim2.fromOffset(14,statsY)
	detail.Stats.Size=UDim2.new(1,-28,0,math.max(28,buttonsTop-statsY-8))
	detail.Stats.TextSize=if narrow or compact then 13 else 16
	detail.Stats.TextXAlignment=Enum.TextXAlignment.Center
	detail.Equip.Position=UDim2.new(0,12,1,-56)
	detail.Equip.Size=UDim2.new(if singleRow then .44 else 1,if singleRow then -16 else -24,0,44)
	detail.Lock.Position=if singleRow then UDim2.new(.44,0,1,-56) else UDim2.new(0,12,1,-106)
	detail.Lock.Size=UDim2.new(if singleRow then .19 else .42,if singleRow then -6 else -16,0,42)
	detail.Pin.Position=if singleRow then UDim2.new(.63,0,1,-56) else UDim2.new(.42,2,1,-106)
	detail.Pin.Size=UDim2.new(if singleRow then .37 else .58,-14,0,42)
	detail.Lock.ButtonText.TextSize=if singleRow then 12 else 16
	detail.Pin.ButtonText.TextSize=if singleRow then 12 else 16
	detail.Equip.ButtonText.TextSize=if singleRow then 11 else 17
	layout.Status.Position=UDim2.new(0,pad,1,-32);layout.Status.Size=UDim2.new(1,-36,0,24)
	layout.Status.TextSize=if narrow then 11 else 13
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
		button.State.Visible=side>=50;button.State.Position=UDim2.new(1,-38,0,3)
	end
	bar.Hint.Size=UDim2.fromOffset(320,26)
	bar.Hint.AnchorPoint=Vector2.new(.5,0)
	bar.Hint.Position=UDim2.new(.5,0,0,-32)
end
return Layout
