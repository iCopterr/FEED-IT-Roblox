-- Opt-in roster, acquisition and migration regression checks. Memory-only Studio.
if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="RosterVerification" then return end
local checks={}
local ok,failure=xpcall(function()
 local storage=game:GetService("ReplicatedStorage")
 local pets=require(storage.Shared.Config.PetConfig)
 local eggs=require(storage.Shared.Config.EggConfig)
 local conveyor=require(storage.Shared.Config.ConveyorConfig)
 local inventory=require(storage.Shared.Config.InventoryConfig)
 local schema=require(script.Parent.Data.PlayerDataSchema)
 local models=require(storage.Shared.PetModels)
 local function check(v,n) assert(v,n);table.insert(checks,n) end
 local seen={};local count=0;local rarityCount=0
 for rarity in pets.Rarities do rarityCount+=1;check(inventory.RarityOrder[rarity] and inventory.RarityColors[rarity],"Rarity presentation "..rarity) end
 check(rarityCount==9 and #eggs.Order==6,"Six eggs / nine rarities")
 for _,eggId in eggs.Order do
  local egg=eggs.Definitions[eggId];check(#egg.Results==6,"Six results "..eggId)
  check(workspace.EggTemplates:FindFirstChild(egg.TemplateName),"Egg template "..eggId)
  local total=0;for _,r in egg.Results do total+=r.Weight end
  check(math.abs(total-100)<.00001,"Normalized odds "..eggId)
  local cursor=0
  for _,r in egg.Results do
   local p=pets.Species[r.SpeciesId]
   check(p and p.EggId==eggId and not seen[r.SpeciesId] and p.BaseIncome>0,"Unique valid result "..r.SpeciesId)
   check(eggs.Pick(eggId,(cursor+r.Weight/2)/total)==r.SpeciesId,"Weighted selection "..r.SpeciesId)
   check(models.GetTemplate(r.SpeciesId),"Model installed "..r.SpeciesId)
   seen[r.SpeciesId]=true;count+=1;cursor+=r.Weight
  end
 end
 local actual=0;for id in pets.Species do actual+=1;check(seen[id],"Species in pool "..id) end
 check(count==36 and actual==36,"Exactly 36 species")
 local total=0;for _,r in conveyor.Offers do total+=r.Weight end
 check(math.abs(total-100)<.00001 and conveyor.Pick(.9995).EggId=="ultimate_egg","Ultimate availability")
 check(eggs.Definitions.ultimate_egg.Price==500000000000 and eggs.Definitions.ultimate_egg.HatchSeconds==2700,"Ultimate price / timer")
 local function oldPet(id,species,rarity,income,level)
  return {DataVersion=2,PetId=id,SpeciesId=species,EggId="supreme_egg",Rarity=rarity,BaseIncome=income,FeedLevel=level,
   Variant="Shiny",Traits={"MigrationSentinel"},Locked=true,Placed=false,CreatedAt=123}
 end
 local original=schema.CreateDefault();original.DataVersion=10
 original.Money=123456;original.Foods.fresh=3
 original.Inventory.owned=oldPet("owned","supreme_pet_1","Legendary",8500,12)
 original.Inventory.owned.Placed=true;original.Inventory.owned.PlotSlot=1
 original.Inventory.owned.PenPosition={X=2,Z=3};original.PlacedPetIds.owned=true
 original.PendingRecovery.recovery={Pet=oldPet("recovery","supreme_pet_2","Legendary",22000,8),AttemptId="attempt",ExplodedAt=1000,FoodSpent=4}
 original.IncubatingEggs.egg={EggId="supreme_egg",Pet=oldPet("reserved","supreme_pet_3","Mythic",32000,0),StartedAt=1000,ReadyAt=2800,PricePaid=50000000000,HatchSeconds=1800,PenPosition={X=1,Z=2}}
 original.PetIndex.supreme_pet_1=true
 local migrated,err=schema.Migrate(original);assert(migrated,err)
 check(migrated.DataVersion==schema.CURRENT_VERSION and migrated.ReviveShards==0 and original.DataVersion==10,"Migration does not mutate source")
 check(original.Inventory.owned.BaseIncome==8500 and original.PendingRecovery.recovery.Pet.Rarity=="Legendary","Old nested records unchanged")
 local p=migrated.Inventory.owned
 check(p.PetId=="owned" and p.FeedLevel==12 and p.Variant=="Shiny" and p.Locked and p.Placed and p.PlotSlot==1 and p.PenPosition.X==2 and p.Traits[1]=="MigrationSentinel" and p.CreatedAt==123,"Pet identity / growth / placement preserved")
 check(p.Rarity=="Mythic" and p.BaseIncome==100000 and p.EggId=="supreme_egg","Moved pet updated; acquisition provenance retained")
 local r=migrated.PendingRecovery.recovery
 check(r.Pet.Rarity=="Fabled" and r.Pet.BaseIncome==220000 and r.Pet.FeedLevel==8 and r.FoodSpent==4 and r.AttemptId=="attempt" and r.ExplodedAt==1000,"Pending revive preserves recovery state")
 local e=migrated.IncubatingEggs.egg
 check(e.EggId=="supreme_egg" and e.Pet.SpeciesId=="supreme_pet_3" and e.Pet.PetId=="reserved" and e.Pet.BaseIncome==320000 and e.Pet.Rarity=="Fabled" and e.ReadyAt==2800 and e.StartedAt==1000 and e.PricePaid==50000000000 and e.HatchSeconds==1800,"Paid egg retains original outcome / price / timer")
 check(migrated.Money==123456 and migrated.Foods.fresh==3 and migrated.ReviveShards==0 and migrated.PetIndex.supreme_pet_1,"Currencies / index preserved")
 local again=assert(schema.Migrate(migrated))
 check(again.Inventory.owned.PetId==p.PetId and again.Inventory.owned.BaseIncome==p.BaseIncome and again.IncubatingEggs.egg.Pet.PetId==e.Pet.PetId,"Migration idempotent")
 original.PendingRecovery.recovery.Pet=false
 check(schema.Migrate(original)==nil,"Malformed migration rejected")
end,debug.traceback)
local result={passed=ok,checks=checks,failure=if ok then nil else tostring(failure)}
print("ROSTER_VERIFICATION "..game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
