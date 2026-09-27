-- Edit-only final verification; works before or after installation.
assert(not game:GetService('RunService'):IsRunning())
local backups=assert(game.ServerStorage:FindFirstChild('PetModelBackups_20260927'))
local staging=game.ServerStorage:FindFirstChild('PetOptimizationCandidates')
local reports={}
local function count(m)
 local n,u,t,j=0,0,0,0
 for _,p in m:GetDescendants()do
  if p:IsA('BasePart')then n+=1 end
  if p:IsA('UnionOperation')then u+=1;t+=p.TriangleCount;assert(p.TriangleCount>0 and p.TriangleCount<20000)end
  if p:IsA('Motor6D')then j+=1 end
 end
 return n,u,t,j
end
for _,source in backups:GetChildren()do
 if not source:IsA('Model')then continue end
 local m=(staging and staging:FindFirstChild(source.Name))or game.ReplicatedStorage.PetsModel:FindFirstChild(source.Name)
 assert(m and m:GetAttribute('SerializationVerified'),source.Name..' missing verified candidate')
 local n,u,t,j=count(m);local old,_,_,oldJ=count(source)
 assert(n<=100 and j==oldJ and n<old/10,source.Name..' budget/rig changed')
 assert(m.PrimaryPart.Name==source.PrimaryPart.Name)
 for key,value in source:GetAttributes()do assert(m:GetAttribute(key)==value,source.Name..' attribute changed: '..key)end
 for _,p in source:GetDescendants()do
  if p:IsA('Motor6D')then
   local q=assert(m:FindFirstChild(p.Parent.Name,true)):FindFirstChild(p.Name)
   assert(q and q:IsA('Motor6D')and q.Part0.Name==p.Part0.Name and q.Part1.Name==p.Part1.Name,'Joint changed')
   assert((q.C0.Position-p.C0.Position).Magnitude<.0001 and(q.C1.Position-p.C1.Position).Magnitude<.0001)
  end
 end
 local connected={[m.PrimaryPart]=true};local changed=true
 while changed do changed=false;for _,joint in m:GetDescendants()do
  if joint:IsA('Motor6D')or joint:IsA('WeldConstraint')then
   local a,b=joint.Part0,joint.Part1
   assert(a and b and a:IsDescendantOf(m)and b:IsDescendantOf(m),'External/missing joint')
   if(connected[a]or connected[b])and not(connected[a]and connected[b])then connected[a]=true;connected[b]=true;changed=true end
  end
 end end
 for _,p in m:GetDescendants()do if p:IsA('BasePart')then assert(connected[p],p.Name..' disconnected')end end
 local data=game:GetService('SerializationService'):SerializeInstancesAsync({m})
 local restored=game:GetService('SerializationService'):DeserializeInstancesAsync(data)[1]
 restored.Parent=game.ServerStorage
 local rn,ru,rt,rj=count(restored)
 assert(n==rn and u==ru and t==rt and j==rj,'Saved geometry/rig mismatch')
 local _,s=m:GetBoundingBox();local _,rs=restored:GetBoundingBox();assert((s-rs).Magnitude<.01)
 restored:ScaleTo(restored:GetScale()*2);local _,grown=restored:GetBoundingBox();assert((grown-s*2).Magnitude<.02)
 restored:Destroy()
 m:SetAttribute('OptimizationError',nil)
 local report={name=source.Name,before=old,after=n,unions=u,unionTriangles=t,motors=j,serializedBytes=buffer.len(data)}
 m:SetAttribute('OptimizationReport',game:GetService('HttpService'):JSONEncode(report))
 table.insert(reports,report)
end
assert(#reports==24,'Expected all 24 models')
table.sort(reports,function(a,b)return a.name<b.name end)
return game:GetService('HttpService'):JSONEncode(reports)
