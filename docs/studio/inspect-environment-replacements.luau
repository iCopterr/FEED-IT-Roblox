assert(not game:GetService('RunService'):IsRunning(), 'Stop Play first')
local out={}
for _,obj in workspace:GetChildren() do
 local name=obj.Name
 local parts={}
 if obj:IsA('BasePart') then table.insert(parts,obj) end
 for _,p in obj:GetDescendants() do if p:IsA('BasePart') then table.insert(parts,p) end end
 local sample={}
 if string.lower(name)=='tree' or string.lower(name)=='rock' then
  for _,p in parts do table.insert(sample,{name=p.Name,class=p.ClassName,size=tostring(p.Size),position=tostring(p.Position),mesh=p:IsA('MeshPart') and p.MeshId or nil}) end
 end
 local children={};for _,p in obj:GetChildren() do table.insert(children,{p.Name,p.ClassName}) end
 out[name]={class=obj.ClassName,parts=#parts,sample=sample,children=children}
end
return game:GetService('HttpService'):JSONEncode(out)
