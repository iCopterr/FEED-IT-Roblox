param([int]$Port=58741)
$ErrorActionPreference='Stop'
$source=Get-Content src/server/Services/EggService.luau -Raw
$timing=Get-Content src/shared/Config/HatchAnimationConfig.luau -Raw
$prefix=@'
assert(not game:GetService('RunService'):IsRunning())
local realGame,realRequire=game,require
local now=100
local function signal() return {Connect=function()end} end
local players={PlayerRemoving=signal(),GetPlayers=function()return {} end}
local character=Instance.new('Model')
local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=character
local humanoid=Instance.new('Humanoid');humanoid.Parent=character
local shell=Instance.new('Model');local part=Instance.new('Part');part.Parent=shell
local player={Parent=players,Character=character}
local profile,egg,pet,locked,carried,saveFailures,rejectGrant
local events,jobs,records={},{},{}
local function reset()
 now+=20;locked=false;carried=nil;saveFailures=0;rejectGrant=false;jobs={};records={}
 player={Parent=players,Character=character}
 pet={PetId='reserved-pet',SpeciesId='test_common',Rarity='Common',Variant='Normal'}
 egg={EggId='prototype_egg',Pet=pet,ReadyAt=0,PenPosition={X=0,Z=0}}
 profile={IncubatingEggs={egg=egg},Inventory={},PetIndex={}}
end
local deps={
 DataService={GetData=function()return profile end,Save=function()
  if saveFailures>0 then saveFailures-=1;return false,'test retry' end
  table.insert(records,{pet=profile.Inventory['reserved-pet'],egg=profile.IncubatingEggs.egg})
  return true
 end},
 PetService={},PlayerDataSchema={Validate=function(p)return not (rejectGrant and p.Inventory['reserved-pet']) end},
 FeedLocks={IsLocked=function()return locked end,Begin=function()if locked then return false end;locked=true;return true end,Finish=function()locked=false end},
 CarryService={GetPetId=function()return carried end,GetEggId=function()return nil end,Equip=function(_,id)carried=id end},
 PlacementService={},PlotService={},
 EggVisuals={GetModel=function()return shell end,Reconcile=function()end,Clear=function()end},
 PedestalService={GetPetId=function()return nil end},TutorialProgress={Record=function()end},
}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
 if name=='Players' then return players end
 return realGame:GetService(name)
end}
local fakeInstance={new=function(class)
 assert(class=='RemoteEvent' or class=='RemoteFunction')
 local remote={FireClient=function(self,_,data)events[self.Name]=data end}
 return remote
end}
local fakeTask={spawn=function(fn)table.insert(jobs,coroutine.create(fn))end,wait=function(seconds)return coroutine.yield(seconds)end}
local fakeWorkspace={GetServerTimeNow=function()return now end}
local fakeOs={clock=function()return now end,time=function()return 1000 end}
'@
$code=$prefix+"`nlocal Timing=(function()`n"+$timing+"`nend)()`n"+@'
deps.HatchAnimationConfig=Timing
local function fakeRequire(module)
 if deps[module.Name] then return deps[module.Name] end
 return realRequire(module)
end
local Service=(function(game,require,task,workspace,script,Instance,os)
'@+"`n"+$source+"`nend)(fakeGame,fakeRequire,fakeTask,fakeWorkspace,realGame.ServerScriptService.Server.Services.EggService,fakeInstance,fakeOs)`n"+@'
Service.Start();jobs={}
local function begin()
 local returned
 local thread=coroutine.create(function()returned=Service.HandleRequest(player,'HatchRemote','egg')end)
 local ok,delay=coroutine.resume(thread);assert(ok,delay)
 assert(coroutine.status(thread)=='suspended','Hatch did not wait: '..tostring(returned and returned.Code))
 return thread,delay,function()return returned end
end
local function resume(thread)
 local ok,err=coroutine.resume(thread);assert(ok,err);return err
end
local function reserved()
 assert(profile.Inventory[pet.PetId]==nil and profile.IncubatingEggs.egg==egg and not carried,'Early grant')
end
reset()
local start=now
local thread,delay,result=begin()
local reward=events.HatchStarted.Reward
assert(reward.SpeciesId==pet.SpeciesId and reward.PetId==pet.PetId,'Wrong preview result')
assert(math.abs(reward.RevealEndsAt-(start+Timing.BurstAt+2))<.001,'Reveal not scheduled at pop')
assert(math.abs(delay-(Timing.BurstAt+2+.3+.8))<.001,'Wrong arrival deadline')
for _,time in {start+Timing.BurstAt,start+Timing.BurstAt+1.9,reward.CollectStartsAt+.2,reward.CollectEndsAt-.01} do
 now=time;reserved()
 assert(Service.HandleRequest(player,'HatchRemote','egg').Code=='Busy','Duplicate accepted during reveal')
 resume(thread);reserved()
end
now=reward.CollectEndsAt;resume(thread)
assert(result().Ok and profile.Inventory[pet.PetId]==pet and profile.IncubatingEggs.egg==nil,'Arrival did not transfer exact pet')
assert(locked and not carried,'Carry before save')
resume(table.remove(jobs,1))
assert(not locked and carried==pet.PetId and #records==1,'Save/carry failed')
assert(records[1].pet==pet and records[1].egg==nil,'Persisted duplicate')
assert(Service.HandleRequest(player,'HatchRemote','egg').PetId==pet.PetId and #jobs==0,'Duplicate completion')
-- Leaving before arrival retains the saved reservation, not an inventory pet.
reset();thread,delay,result=begin();reserved();player.Parent=nil;now+=delay;resume(thread)
assert(result().Code=='Loading' and not locked);reserved()
-- The same egg/result is safe to retry on return.
player.Parent=players;now+=1;thread,delay,result=begin();now+=delay;resume(thread)
assert(result().Ok and result().PetId==pet.PetId);resume(table.remove(jobs,1))
-- Schema rejection restores the egg and index rather than losing the pet.
reset();thread,delay,result=begin();rejectGrant=true;now+=delay;resume(thread)
assert(result().Code=='InvalidData' and not locked and profile.PetIndex[pet.SpeciesId]==nil);reserved()
-- A failed save holds the transaction; retry saves exactly one pet and then carries.
reset();thread,delay,result=begin();saveFailures=1;now+=delay;resume(thread)
local saving=table.remove(jobs,1);local retryDelay=resume(saving)
assert(locked and not carried and profile.Inventory[pet.PetId]==pet and #records==0)
now+=retryDelay;resume(saving)
assert(not locked and carried==pet.PetId and #records==1 and records[1].egg==nil)
reset();egg.ReadyAt=1010
local offer=Service.HandleRequest(player,'HatchRemote','egg')
assert(offer.Code=='GrowNowUnavailable' and offer.Robux==29 and offer.EggUid=='egg')
assert(events.GrowNowOffer==offer and not locked and #jobs==0);reserved()
now+=1
offer=Service.HandleRequest(player,'Hatch','egg')
assert(offer.Code=='GrowNowUnavailable' and offer.Robux==29);reserved()
now+=1;root.Position=Vector3.new(1000,0,0)
assert(Service.HandleRequest(player,'Hatch','egg').Code=='TooFar');reserved()
character:Destroy();shell:Destroy()
return 'PASS actual EggService: pop result, no grant before light arrival, exact reserved identity, duplicates, disconnect/retry, rollback, save retry'
'@
$body=@{jsonrpc='2.0';id=1020;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
