-- Versioned, server-only commerce state is stored as a scalar JSON Settings
-- entry so existing profile migration/cloning preserves it atomically.
local Http=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config.MonetizationConfig)
local Shop=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local Food=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
local Revive=require(game.ReplicatedStorage.Shared.Config.ReviveConfig)
local State={}
function State.Read(data)
 local raw=data.Settings.CommerceV1
 if raw==nil then return {Version=1,Receipts={}} end
 assert(type(raw)=="string","Invalid commerce data")
 local value=Http:JSONDecode(raw)
 assert(value.Version==1 and type(value.Receipts)=="table","Invalid commerce version")
 return value
end
function State.Write(data,value)
 data.Settings.CommerceV1=Http:JSONEncode(value)
end
function State.RestockId(data,now)
 local cycle=Shop.GetRestockId(now)
 if type(data.Settings.PersonalStockExpiresAt)=="number" and now<data.Settings.PersonalStockExpiresAt
  and type(data.Settings.PersonalStockId)=="number" then
  return data.Settings.PersonalStockId, data.Settings.PersonalStockExpiresAt
 elseif data.Settings.PersonalStockCycle==cycle and type(data.Settings.PersonalStockId)=="number" then
  -- Preserve an already-paid legacy restock until its original cycle ends.
  return data.Settings.PersonalStockId, (cycle+1)*Shop.RestockSeconds
 end
 return cycle,(cycle+1)*Shop.RestockSeconds
end
function State.Stock(data,now)
 local id,expiresAt=State.RestockId(data,now)
 local source=id
 if id==data.Settings.PersonalStockId and type(data.Settings.PersonalStockSourceId)=="number" then
  source=data.Settings.PersonalStockSourceId
 end
 return id,expiresAt,Shop.GetStock(source),source
end
function State.Reserved(data,stock,slot)
 local p=State.Read(data).Pending
 return p~=nil and p.Kind=="Food" and p.Stock==stock and p.Slot==slot
end
function State.ReviveReserved(data,petId,attempt)
 local p=State.Read(data).Pending
 return p~=nil and p.Kind=="Revive" and p.PetId==petId and p.AttemptId==attempt
end
local function ready(egg,now)
 if egg and egg.StartedAt>0 and egg.ReadyAt>now then
  egg.ReadyAt=math.max(egg.StartedAt,now)
  egg.HatchSeconds=egg.ReadyAt-egg.StartedAt
 end
end
function State.Grant(data,state,p,now)
 if p.Kind=="Money" then data.Money+=p.Money
 elseif p.Kind=="Welcome" then
  if state.WelcomeClaimed then return false end
  Food.Add(data,"hearty",Config.WelcomePack.Hearty)
  Food.Add(data,"royal",Config.WelcomePack.Royal)
  data.ReviveCharges+=Config.WelcomePack.Revive;state.WelcomeClaimed=true
 elseif p.Kind=="Food" then
  if p.ItemId=="revive" then
   data.ReviveCharges+=1
  else
   Food.Add(data,p.ItemId,1)
   local definition=Food.Types[p.ItemId]
   local shards=definition and Revive.Shards.ByRarity[definition.Rarity]
   assert(type(shards)=="number" and shards>0,"Missing paid food shard reward")
   data.ReviveShards+=shards
  end
  if data.MerchantRestockId~=p.Stock then
   -- A paid old reservation must not replace newer-cycle purchase history.
   local current=State.RestockId(data,now)
   if current==p.Stock then data.MerchantRestockId=p.Stock;data.MerchantPurchases={} end
  end
  if data.MerchantRestockId==p.Stock then data.MerchantPurchases[tostring(p.Slot)]=true end
 elseif p.Kind=="Grow" then ready(data.IncubatingEggs[p.EggUid],now)
 elseif p.Kind=="GrowAll" then for _,id in p.Eggs do ready(data.IncubatingEggs[id],now) end
 elseif p.Kind=="Restock" then
  local revision=(data.Settings.PersonalStockRevision or 0)+1
  data.Settings.PersonalStockRevision=revision
  -- Separate namespace from global timestamp cycles; persists through rejoin.
  data.Settings.PersonalStockId=1000000000+revision
  data.Settings.PersonalStockSourceId=p.SourceStockId
  data.Settings.PersonalStockExpiresAt=now+Shop.RestockSeconds
  data.MerchantRestockId=data.Settings.PersonalStockId;data.MerchantPurchases={}
 elseif p.Kind=="Revive" then
  local record=data.PendingRecovery[p.PetId]
  if not record or record.AttemptId~=p.AttemptId or data.Inventory[p.PetId] then return false end
  data.Inventory[p.PetId]=record.Pet
  data.PendingRecovery[p.PetId]=nil
 else return false end
 return true
end
return table.freeze(State)
