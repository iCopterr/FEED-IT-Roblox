-- Opt-in shape/scale invariants for all authored pets; no player data mutations.
if not game:GetService('RunService'):IsStudio() then return end
local testing=game:GetService('StudioTestService')
if testing:GetTestArgs()~='PetSizeVerification' then return end
local checks={}
local ok,failure=xpcall(function()
 local shared=game.ReplicatedStorage.Shared
 local pets=require(shared.Config.PetConfig)
 local models=require(shared.PetModels)
 local feed=require(shared.Config.FeedConfig)
 local function check(v,n)assert(v,n);table.insert(checks,n)end
 local heights={}
 for id,def in pets.Species do
  local template=assert(models.GetTemplate(id));local sourceScale=template:GetScale()
  local m=template:Clone()
  local n=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then n+=1 end end
  m:ScaleTo(models.GetScale(id,0));local _,base=m:GetBoundingBox();heights[id]=base.Y
  check(math.abs(Vector2.new(base.X,base.Z).Magnitude-def.BaseFootprint)<.04,def.DisplayName..' base footprint')
  for _,level in {10,40}do
   m:ScaleTo(models.GetScale(id,level));local _,size=m:GetBoundingBox()
   -- Roblox clamps very thin legacy parts at small scales; allow 1% bounds error.
   local growth=math.min(feed.GetScale(level),pets.MaxWorldFootprint/def.BaseFootprint)
   check((size-base*growth).Magnitude<(base*growth).Magnitude*.01,def.DisplayName..' growth '..level)
   check(Vector2.new(size.X,size.Z).Magnitude+1<44,def.DisplayName..' rotation-safe maximum footprint')
  end
  local after=0;for _,p in m:GetDescendants()do
   if p:IsA('BasePart')then after+=1 end
   if p:IsA('Motor6D')then check((p.Part0.CFrame*p.C0).Position:FuzzyEq((p.Part1.CFrame*p.C1).Position,.01),def.DisplayName..' scaled motor')end
  end
  check(after==n and template:GetScale()==sourceScale,def.DisplayName..' template and part count unchanged')
  m:Destroy()
 end
 check(heights.master_pet_1>heights.test_common*2.4,'Hydra is over 2.4 chickens tall at base level')
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
