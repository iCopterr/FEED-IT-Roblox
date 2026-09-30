local Notice=require(script.Parent.Parent.UI.Notifications)
local Controller={}
local started=false
function Controller.Start()
	if started then return end;started=true
	local playerGui=game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui=playerGui:WaitForChild("FeedYourPetUI",30)
	if not gui or not gui:FindFirstChild("Notification") then return end
	local paths={FeedYourPetUI={{"Inventory","Panel","Layout","Status"},{"FeedPanel","Status"}},
		MerchantUI={{"Panel","Status"}},ReviveUI={{"Panel","Status"}},PenManagerUI={{"Panel","Status"}},
		IndexUI={{"Panel","Status"}},DebugUI={{"Panel","Status"}}}
	for name,entries in paths do
		task.spawn(function()
			local screen=playerGui:WaitForChild(name,30);if not screen then return end
			for _,path in entries do
				local label=screen
				for _,child in path do label=label:FindFirstChild(child);if not label then break end end
				if label then
					label.Visible=false
					label:GetPropertyChangedSignal("Text"):Connect(function() Notice.Show(label.Text) end)
				end
			end
		end)
	end
	local function position() Notice.Position(gui) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(position)
	gui.Hotbar:GetPropertyChangedSignal("AbsoluteSize"):Connect(position)
	gui.Hotbar:GetPropertyChangedSignal("AbsolutePosition"):Connect(position)
	position()
end
return Controller
