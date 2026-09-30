local Controller={}
function Controller.Start()
	local gui=game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("PenManagerUI",30)
	if not gui then return end
	local panel=gui:WaitForChild("GrowNow",10)
	if not panel then return end
	local Motion=require(script.Parent.Parent.UI.Motion)
	Motion.BindPopup(panel)
	panel.Visible=false;panel.Buy.Active=false
	panel.Close.Activated:Connect(function() Motion.Close(panel) end)
	game.ReplicatedStorage:WaitForChild("GrowNowOffer").OnClientEvent:Connect(function(offer)
		if type(offer)~="table" or offer.Code~="GrowNowUnavailable" then return end
		panel.Summary.Text=offer.Name.."\nFinish its remaining hatch time"
		panel.Buy.ButtonText.Text="GROW NOW • "..offer.Robux.." ROBUX • SOON"
		panel.Buy.Active=false;panel.Visible=true
	end)
	local function resize()
		panel.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/540,(gui.AbsoluteSize.Y-24)/240))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
end
return Controller
