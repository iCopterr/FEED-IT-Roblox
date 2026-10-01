-- Run in Studio edit mode. Policy API and Players are mocked; no live player policy is queried.
local root=game.ServerScriptService.Server
local events={}
local function signal(name)
 return {Connect=function(_,callback)events[name]=callback end}
end
local players={PlayerAdded=signal("Added"),PlayerRemoving=signal("Removing")}
players.GetPlayers=function()return {} end
local responses={}
local policy={GetPolicyInfoForPlayerAsync=function(_,player)
 local response=responses[player]
 if type(response)=="string" then error(response) end
 return response
end}
local spawned={}
local fakeTask={
 spawn=function(callback,...)table.insert(spawned,{callback,...})end,
 wait=function()end,
}
local function player(name)
 local attributes={}
 return {
  Name=name,Parent=players,
  SetAttribute=function(_,key,value)attributes[key]=value end,
  GetAttribute=function(_,key)return attributes[key] end,
 }
end
local env=setmetatable({
 script=root.Services.PolicyEligibilityService,
 game={GetService=function(_,name)
  if name=="Players" then return players end
  if name=="PolicyService" then return policy end
  return game:GetService(name)
 end},
 task=fakeTask,
},{__index=getfenv()})
local fn=assert(loadstring(root.Services.PolicyEligibilityService.Source));setfenv(fn,env)
local service=fn();service.Start();service.Start()
local function join(target,response)
 responses[target]=response;events.Added(target)
 assert(target:GetAttribute("MoneyPacksAllowed")==false)
 assert(target:GetAttribute("MoneyPacksPolicyStatus")=="Loading")
 local work=table.remove(spawned,1);work[1](table.unpack(work,2))
end
local allowed=player("Allowed")
join(allowed,{ArePaidRandomItemsRestricted=false})
assert(allowed:GetAttribute("MoneyPacksAllowed")==true)
assert(allowed:GetAttribute("MoneyPacksPolicyStatus")=="Allowed")
assert(allowed:GetAttribute("PaidRandomItemsRestricted")==false)
assert(service.MoneyPacksAllowed(allowed)==true)
local restricted=player("Restricted")
join(restricted,{ArePaidRandomItemsRestricted=true})
local ok,code=service.MoneyPacksAllowed(restricted)
assert(not ok and code=="PolicyRestricted")
assert(restricted:GetAttribute("MoneyPacksAllowed")==false)
assert(restricted:GetAttribute("MoneyPacksPolicyStatus")=="Restricted")
assert(restricted:GetAttribute("PaidRandomItemsRestricted")==true)
local failed=player("Failed")
join(failed,"temporary outage")
ok,code=service.MoneyPacksAllowed(failed)
assert(not ok and code=="PolicyUnavailable")
assert(failed:GetAttribute("MoneyPacksPolicyStatus")=="Unavailable")
local malformed=player("Malformed")
join(malformed,{})
ok,code=service.MoneyPacksAllowed(malformed)
assert(not ok and code=="PolicyUnavailable")
events.Removing(allowed)
ok,code=service.MoneyPacksAllowed(allowed)
assert(not ok and code=="PolicyUnavailable")
local departed=player("Departed")
responses[departed]={ArePaidRandomItemsRestricted=false};events.Added(departed)
events.Removing(departed);departed.Parent=nil
local late=table.remove(spawned,1);late[1](table.unpack(late,2))
ok,code=service.MoneyPacksAllowed(departed)
assert(not ok and code=="PolicyUnavailable")
return "PASS: allowed, restricted, API failure, malformed result, fail-closed attributes, retry, cleanup and deferred-leave race"
