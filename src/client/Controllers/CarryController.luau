local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local CarryController = {}

function CarryController.Start()
	local player = Players.LocalPlayer
	local plots = workspace:WaitForChild("PlayerPlots")
	-- Visibility is client-specific. All permission/time/range checks stay server-side.
	task.spawn(function()
		while true do
			for _, plot in plots:GetChildren() do
				local pen = plot:FindFirstChild("Pen")
				local floor = pen and pen:FindFirstChild("Floor")
				local prompt = floor and floor:FindFirstChild(Config.PromptName)
				if prompt then
					prompt.Enabled = plot:GetAttribute("OwnerUserId") == player.UserId and player:GetAttribute("CarriedPetId") ~= nil
				end
			end
			task.wait(.1)
		end
	end)
	game.ReplicatedStorage:WaitForChild("CarryFeedback").OnClientEvent:Connect(function(ok, code)
		if ok then return end
		local gui = player.PlayerGui:FindFirstChild("FeedYourPetUI")
		if gui then
			local modal = gui.Inventory
			modal.Visible = true
			modal.Panel.Layout.Status.Text = if code == "PenFull" then "Your Pen is full. Pick up another pet first." else "Placement cancelled. Move into your Pen and hold E again."
		end
	end)
end

return CarryController
