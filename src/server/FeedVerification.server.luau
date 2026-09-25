-- Resolver and save-compatibility coverage. Feed/Rescue transactions run in FoodShopVerification.
if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="FeedVerification" then return end
local checks={}
local ok,failure=xpcall(function()
 local resolver=require(script.Parent.Services.FeedResolver)
 local schema=require(script.Parent.Data.PlayerDataSchema)
 local config=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
 local food=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
 local function check(value,name) assert(value,name);table.insert(checks,name) end
 local function random(values)
  local i=0
  return function() i+=1;assert(values[i]~=nil,"Unexpected extra RNG roll");return values[i] end
 end
 local previousScale=config.GetScale(0)
 check(previousScale==1,"Feed level zero uses base visual scale")
 for level=1,config.MaxConfiguredLevel do
  local scale=config.GetScale(level)
  check(scale>previousScale,"Visual growth increases at level "..level)
  previousScale=scale
 end
 check(math.abs(previousScale-config.MaxVisualScale)<1e-5,"Level 40 reaches configured visual scale")
 for _,case in {{0,.1,"Normal",1},{0,.945,"Critical",2},{17,.995,"Mega",20},{38,.9995,"Insane",40},{39,.945,"Critical",40}} do
  local result=resolver.Roll(case[1],random({.99,case[2]}))
  check(result.Critical==case[3] and result.FeedLevel==case[4],"Critical outcome "..case[3].." at "..case[1])
 end
 check(resolver.Roll(20,random({0,0})).Code=="MiracleSave","Miracle skips Critical")
 check(resolver.Roll(20,random({0,.5})).Code=="Explosion","Explosion skips Critical")
 check(not pcall(resolver.Roll,40,random({})),"Level 40 cannot feed")
 for _,invalid in {-1,.5,0/0,math.huge} do
  check(not pcall(resolver.Roll,invalid,random({})),"Reject invalid Feed level "..tostring(invalid))
 end
 for level=36,39 do
  for _,roll in {.1,.945,.995,.9995} do
   check(resolver.Roll(level,random({.99,roll})).FeedLevel<=40,"Cap "..level.." roll "..roll)
  end
 end
 for id,definition in food.Types do
  local risk=config.ExplosionChance[21]*(1-definition.Reduction)
  check(resolver.Roll(20,random({risk-.001,.5}),risk).Code=="Explosion","Food risk below boundary "..id)
  check(resolver.Roll(20,random({risk,.1}),risk).Code=="Success","Food risk at boundary "..id)
 end
 for _,version in {2,6,8} do
  local old=schema.CreateDefault();old.DataVersion=version
  old.Money=12345;old.Tokens=9;old.ProtectionTokens=3
  if version==2 then old.PendingRecovery=nil end
  local migrated=assert(schema.Migrate(old))
  check(migrated.DataVersion==schema.CURRENT_VERSION and migrated.Money==12345,"Preserve money migrating v"..version)
  check(migrated.Tokens==0 and migrated.ProtectionTokens==0,"Retired currencies cleared by v9 migration from v"..version)
  check(old.Tokens==9 and old.ProtectionTokens==3,"Migration leaves source untouched v"..version)
  check(schema.Validate(migrated),"Migrated save validates v"..version)
 end
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
