local Notice=require(script.Parent.Notifications)
local Purchases={}
local busy=false
local messages={
 Owned="Already owned.",Unavailable="This offer is no longer available.",
 PurchasePending="Your previous purchase is still being resolved.",
 PersistenceRequired="Purchases require a saved-data server.",
 SupportRequired="Please contact support before another purchase.",
	PolicyRestricted="Money packs aren't available for this account.",
	PolicyLoading="Checking whether Money Packs are available…",
	PolicyUnavailable="Money Pack eligibility couldn't be verified. Please rejoin and try again.",
 Loading="Your data is still loading.",
 Busy="Finish your current action before buying.",
}
function Purchases.Request(kind,arg,extra)
 if busy then return end
 busy=true
 local storage=game.ReplicatedStorage
 local ok,result=pcall(function()
  local remote=storage:WaitForChild("MonetizationRequest",10)
  assert(remote,"Purchase service unavailable")
  return remote:InvokeServer(kind,arg,extra)
 end)
 busy=false
 if not ok then Notice.Show("Purchase connection interrupted. Please rejoin if it stays pending.")
 elseif not result.Ok and messages[result.Code] then Notice.Show(messages[result.Code]) end
 return ok and result.Ok
end
return Purchases
