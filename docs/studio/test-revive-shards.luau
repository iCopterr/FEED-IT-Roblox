-- Run in Studio edit mode. Uses a detached profile and mocked player/save state.
local root=game.ServerScriptService.Server
local realRequire=require
local Schema=realRequire(root.Data.PlayerDataSchema)
local legacy=Schema.CreateDefault();legacy.DataVersion=11;legacy.ReviveShards=nil
local migrated=assert(Schema.Migrate(legacy))
assert(migrated.DataVersion==Schema.CURRENT_VERSION and migrated.ReviveShards==0 and legacy.ReviveShards==nil)
local profile=Schema.CreateDefault()
local players={}
local rootPart={Position=Vector3.new(100,0,0)}
local humanoid={Health=100}
local character={
 FindFirstChild=function(_,name) return if name=="HumanoidRootPart" then rootPart else nil end,
 FindFirstChildOfClass=function(_,name) return if name=="Humanoid" then humanoid else nil end,
}
local player={Parent=players,Character=character}
local point={Position=Vector3.zero}
local machine={FindFirstChild=function(_,name) return if name=="InteractionPoint" then point else nil end}
local fakeWorkspace={FindFirstChild=function(_,name) return if name=="ReviveMachine" then machine else nil end}
local locked=false
local saves=0
local deps={
 [root.Services.DataService]={GetData=function(who)return if who==player then profile else nil end,
  Save=function(who)assert(who==player);saves+=1;return true end},
 [root.Data.PlayerDataSchema]=Schema,
 [root.Services.FeedLocks]={Begin=function()if locked then return false end;locked=true;return true end,
  Finish=function()locked=false end,IsLocked=function()return locked end},
 [root.Services.MoneyService]={GetPetRate=function()return 0 end},
 [root.Services.CommerceState]={ReviveReserved=function()return false end},
}
local clock=0
local env=setmetatable({
 script=root.Services.ReviveService,
 require=function(module)return deps[module] or realRequire(module) end,
 game={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
  if name=="Players" then return players end
  return game:GetService(name)
 end},
 workspace=fakeWorkspace,
 os={time=os.time,clock=function()clock+=1;return clock end},
 task={spawn=function(callback,...)callback(...)end,wait=function()end},
},{__index=getfenv()})
local fn=assert(loadstring(root.Services.ReviveService.Source));setfenv(fn,env)
local service=fn()

profile.ReviveShards=99
assert(service.HandleRequest(player,"Exchange",1).Code=="TooFar" and profile.ReviveShards==99)
rootPart.Position=Vector3.zero
assert(service.HandleRequest(player,"Exchange",1).Code=="NotEnoughShards" and profile.ReviveCharges==0)
profile.ReviveShards=100
local first=service.HandleRequest(player,"Exchange",1)
assert(first.Ok and first.Code=="Exchanged" and first.ReviveShards==0 and first.ReviveCharges==1)
assert(profile.ReviveShards==0 and profile.ReviveCharges==1 and saves==1 and not locked)
local replay=service.HandleRequest(player,"Exchange",1)
assert(replay.Ok and replay.NextExchangeSequence==2 and saves==1 and profile.ReviveCharges==1)
assert(service.HandleRequest(player,"Exchange",3).Code=="StaleRequest" and profile.ReviveCharges==1)
profile.ReviveShards=200
local second=service.HandleRequest(player,"Exchange",2)
assert(second.Ok and profile.ReviveShards==100 and profile.ReviveCharges==2 and saves==2)
local snapshot=service.HandleRequest(player,"Snapshot")
assert(snapshot.Ok and snapshot.ReviveShards==100 and snapshot.ReviveCharges==2
 and snapshot.ShardExchangeCost==100 and snapshot.CanExchange and snapshot.NextExchangeSequence==3)
assert(Schema.Validate(profile))
print("PASS: revive shard exchange distance, balance, persistence, replay and sequence checks.")
