local Notice=require(script.Parent.Notifications)
local Purchases={}
local busy=false
local listening=false
local messages={
 Owned="Already owned.",Unavailable="This offer is no longer available.",
 PurchasePending="Your previous purchase is still being resolved.",
 PersistenceRequired="Purchases require a saved-data server.",
 SupportRequired="Please contact support before another purchase.",
 Loading="Your data is still loading.",
}
function Purchases.Request(kind,arg,extra)
 if busy then return end
 busy=true
 local storage=game.ReplicatedStorage
 if not listening then
  listening=true
  storage:WaitForChild("MonetizationNotice").OnClientEvent:Connect(function(message) Notice.Show(message) end)
 end
 local ok,result=pcall(function() return storage:WaitForChild("MonetizationRequest"):InvokeServer(kind,arg,extra) end)
 busy=false
 if not ok then Notice.Show("Purchase connection interrupted. Please rejoin if it stays pending.")
 elseif not result.Ok and messages[result.Code] then Notice.Show(messages[result.Code]) end
 return ok and result.Ok
end
return Purchases
