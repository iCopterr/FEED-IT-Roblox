local Motion=require(script.Parent.Parent.UI.Motion)
local Controller={}
function Controller.Start()
	local gui=game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local function bind(panel)
		Motion.BindPopup(panel)
		local function button(o) if o:IsA("GuiButton") then Motion.BindButton(o,panel) end end
		for _,o in panel:GetDescendants() do button(o) end
		panel.DescendantAdded:Connect(button)
	end
	for _,name in {"FeedYourPetUI","MerchantUI","ReviveUI","DebugUI"} do
		task.spawn(function()
			local screen=gui:WaitForChild(name,30)
			if not screen then return end
			if name=="FeedYourPetUI" then bind(screen.Inventory);bind(screen.FeedPanel) else bind(screen.Panel) end
		end)
	end
end
return Controller
