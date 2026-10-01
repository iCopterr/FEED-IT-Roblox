local TweenService=game:GetService("TweenService")
local Images=require(game.ReplicatedStorage.Shared.Config.MonetizationImages)
local Shine={}
local bound=setmetatable({},{__mode="k"})
local TURN_SECONDS=24

function Shine.Bind(gui)
	if bound[gui] then return end
	bound[gui]=true
	local panel=gui.Panel
	local connections,tweens={},{}
	local function connect(signal,callback)
		table.insert(connections,signal:Connect(callback))
	end
	for _,card in panel.Offers:GetChildren() do
		local art=card:FindFirstChild("Artwork")
		local layer=card:FindFirstChild("ItemShine")
		local rays=layer and layer:FindFirstChild("Rays")
		if not art or not rays then continue end
		rays.Image=Images.ShopShine
		local function resize()
			local size=card.AbsoluteSize
			if size.X<=0 or size.Y<=0 then return end
			-- Align to the actual owner-authored artwork, including scaled layouts.
			local center=art.AbsolutePosition+art.AbsoluteSize*.5-card.AbsolutePosition
			local side=math.max(art.AbsoluteSize.X,art.AbsoluteSize.Y)*1.5
			rays.Position=UDim2.fromScale(center.X/size.X,center.Y/size.Y)
			rays.Size=UDim2.fromScale(side/size.X,side/size.Y)
		end
		connect(art:GetPropertyChangedSignal("AbsoluteSize"),resize)
		connect(art:GetPropertyChangedSignal("AbsolutePosition"),resize)
		connect(card:GetPropertyChangedSignal("AbsoluteSize"),resize)
		resize()
		local tween=TweenService:Create(rays,TweenInfo.new(TURN_SECONDS,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),
			{Rotation=rays.Rotation+360})
		table.insert(tweens,{Tween=tween,Card=card})
		connect(card:GetPropertyChangedSignal("Visible"),function()
			if gui.Enabled and panel.Visible and card.Visible then tween:Play() else tween:Pause() end
		end)
	end
	local function visibility()
		for _,entry in tweens do
			if gui.Enabled and panel.Visible and entry.Card.Visible then entry.Tween:Play() else entry.Tween:Pause() end
		end
	end
	connect(gui:GetPropertyChangedSignal("Enabled"),visibility)
	connect(panel:GetPropertyChangedSignal("Visible"),visibility)
	connect(gui.Destroying,function()
		for _,entry in tweens do entry.Tween:Cancel() end
		for _,connection in connections do connection:Disconnect() end
		bound[gui]=nil
	end)
	visibility()
end

return Shine
