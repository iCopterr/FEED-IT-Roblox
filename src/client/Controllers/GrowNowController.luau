local Controller={}
local Purchases=require(script.Parent.Parent.UI.Purchases)
local started=false
function Controller.Start()
	if started then return end
	started=true
	-- Both the pen menu and the world Hatch prompt send this server offer.
	-- Request native checkout directly; the server revalidates the egg and tier.
	game.ReplicatedStorage:WaitForChild("GrowNowOffer").OnClientEvent:Connect(function(offer)
		if type(offer)~="table" or offer.Code~="GrowNowUnavailable"
			or type(offer.EggUid)~="string" or offer.EggUid=="" then return end
		Purchases.Request("Grow",offer.EggUid)
	end)
end
return Controller
