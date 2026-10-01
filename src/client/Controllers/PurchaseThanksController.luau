local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PurchaseThanks = require(script.Parent.Parent.UI.PurchaseThanks)
local Notifications = require(script.Parent.Parent.UI.Notifications)

local Controller = {}

function Controller.Start()
	local remote = ReplicatedStorage:WaitForChild("MonetizationNotice")
	remote.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" then
			PurchaseThanks.Show(payload)
		elseif type(payload) == "string" then
			-- Backward compatibility for a server that updates before this client.
			Notifications.Show(payload)
		end
	end)
	-- Receipts can finish during client startup. The server queues their visual
	-- acknowledgement until this listener is ready; fulfillment never depends on it.
	remote:FireServer("Ready")
end

return Controller
