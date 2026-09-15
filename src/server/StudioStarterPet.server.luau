-- Requested test pet for the developer, never a production starter reward.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local testing = game:GetService("StudioTestService")
local testArgs = testing:GetTestArgs()
local verifying = testArgs == "StudioStarterPetVerification"
if testArgs and testArgs ~= "" and not verifying then return end
local adapter = require(script.Parent.Data.DataStoreAdapter)
if not adapter.IsMemory() then return end
local Players = game:GetService("Players")
local DataService = require(script.Parent.Services.DataService)
local PetService = require(script.Parent.Services.PetService)
local DEVELOPER_USER_ID = 5250447342
local pending = {}

local function grant(player)
	if player.UserId ~= DEVELOPER_USER_ID or pending[player] then return end
	pending[player] = true
	local deadline = os.clock() + 60
	while player.Parent == Players and not DataService.IsLoaded(player) and os.clock() < deadline do
		task.wait(.1)
	end
	local data = DataService.GetData(player)
	if not data then return end
	-- Do not top up an existing inventory or duplicate pets on respawn/rejoin.
	if next(data.Inventory) == nil then
		local pet, reason = PetService.CreatePet(player, "test_common")
		if not pet then warn("[StudioStarterPet] " .. tostring(reason)); return end
		print("[StudioStarterPet] Added test pet for " .. player.Name)
	end
	if verifying then
		local count, pet = 0, nil
		for _, value in data.Inventory do count += 1; pet = value end
		testing:EndTest({passed = count == 1 and pet.SpeciesId == "test_common" and not pet.Placed, userId = player.UserId, count = count})
	end
end

Players.PlayerAdded:Connect(function(player) task.spawn(grant, player) end)
Players.PlayerRemoving:Connect(function(player) pending[player] = nil end)
for _, player in Players:GetPlayers() do task.spawn(grant, player) end
