assert(not game:GetService('RunService'):IsRunning())
local expected={prototype_egg=12,advanced_egg=14,elite_egg=15,master_egg=19,supreme_egg=24,ultimate_egg=18}
local report={}
for id,parts in expected do
 local m=assert(workspace.EggTemplates:FindFirstChild(id))
 local count,emitters,rate=0,0,0
 for _,item in m:GetDescendants()do
  if item:IsA('BasePart')then count+=1 end
  if item:IsA('ParticleEmitter')then
   emitters+=1;rate+=item.Rate
   assert(item.Parent:IsA('Attachment') and item.Enabled and item.LockedToPart)
   assert(item.Lifetime.Max<=2.201 and item.Rate<=7)
   assert(#item.Size.Keypoints==4 and #item.Transparency.Keypoints==4)
   assert(item.Transparency.Keypoints[1].Value==1 and item.Transparency.Keypoints[4].Value==1)
   assert(item.Texture:find('rbxasset://textures/particles/',1,true))
  end
  if item:IsA('PointLight')then assert(not item.Shadows and item.Range<=7 and item.Brightness<=.45+.001)end
 end
 assert(count==parts and emitters>=2 and rate<=32)
 table.insert(report,{egg=id,parts=count,emitters=emitters,rate=rate})
end
local review=workspace:FindFirstChild('RectangularEggReview')
if review then
 for _,item in review:GetDescendants()do if item:IsA('ParticleEmitter')then item:Emit(math.ceil(item.Rate))end end
end
return game:GetService('HttpService'):JSONEncode(report)
