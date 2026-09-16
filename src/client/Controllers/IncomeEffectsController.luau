local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Shared.Config.MoneyConfig)
local IncomeEffectsController = {}

function IncomeEffectsController.Start()
	local player = Players.LocalPlayer
	local template = ReplicatedStorage:WaitForChild("PetIncomePopup")
	ReplicatedStorage:WaitForChild("PetIncome").OnClientEvent:Connect(function(payout)
		local plots = workspace:FindFirstChild("PlayerPlots")
		if not plots then return end
		local activePets
		for _, plot in plots:GetChildren() do
			if plot:GetAttribute("OwnerUserId") == player.UserId then
				activePets = plot.Pen:FindFirstChild("ActivePets")
				break
			end
		end
		if not activePets then return end
		for _, entry in payout.Pets do
			local pet = activePets:FindFirstChild(entry.PetId)
			local part = pet and (pet:FindFirstChild("Body") or pet:FindFirstChildWhichIsA("BasePart", true))
			if part then
				local popup = template:Clone()
				popup.Adornee = part
				popup.Amount.Text = "+" .. string.format("%.2f", entry.Amount):gsub("0+$", ""):gsub("%.$", "")
				popup.Parent = player.PlayerGui
				local tween = TweenInfo.new(Config.PopupSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(popup, tween, {StudsOffset = popup.StudsOffset + Vector3.new(0,Config.PopupRise,0)}):Play()
				TweenService:Create(popup.Amount, tween, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
				Debris:AddItem(popup, Config.PopupSeconds)
			end
		end
	end)
end

return IncomeEffectsController
