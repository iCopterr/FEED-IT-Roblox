assert(not game:GetService('RunService'):IsRunning())
local configClone=game.ReplicatedStorage.Shared.Config.PetConfig:Clone();configClone.Parent=game.ServerStorage
local feedClone=game.ReplicatedStorage.Shared.Config.FeedConfig:Clone();feedClone.Parent=game.ServerStorage
local config=require(configClone);local feed=require(feedClone);configClone:Destroy();feedClone:Destroy()
local checks=0
for _,def in config.Species do
 local template=assert(game.ReplicatedStorage.PetsModel:FindFirstChild(def.TemplateName),def.DisplayName)
 local sourceScale=template:GetScale();local clone=template:Clone();local partCount=0
 for _,item in clone:GetDescendants()do if item:IsA('BasePart')then partCount+=1 end end
 local _,raw=clone:GetBoundingBox();local footprint=Vector2.new(raw.X,raw.Z).Magnitude
 local baseScale=sourceScale*def.BaseFootprint/footprint;clone:ScaleTo(baseScale)
 local _,base=clone:GetBoundingBox();assert(math.abs(Vector2.new(base.X,base.Z).Magnitude-def.BaseFootprint)<.04,def.DisplayName..' base');checks+=1
 for _,level in {10,40}do
  local growth=math.min(feed.GetScale(level),config.MaxWorldFootprint/def.BaseFootprint)
  clone:ScaleTo(baseScale*growth);local _,size=clone:GetBoundingBox()
  assert((size-base*growth).Magnitude<(base*growth).Magnitude*.01,def.DisplayName..' growth');checks+=1
  assert(Vector2.new(size.X,size.Z).Magnitude+1<44,def.DisplayName..' pen fit');checks+=1
 end
 local after=0
 for _,item in clone:GetDescendants()do
  if item:IsA('BasePart')then after+=1 end
  if item:IsA('Motor6D')then assert((item.Part0.CFrame*item.C0).Position:FuzzyEq((item.Part1.CFrame*item.C1).Position,.01),def.DisplayName..' motor');checks+=1 end
 end
 assert(after==partCount and template:GetScale()==sourceScale,def.DisplayName..' unchanged');checks+=1;clone:Destroy()
end
return ('PASS: %d pet size geometry checks'):format(checks)
