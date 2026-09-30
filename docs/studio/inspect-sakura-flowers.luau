local results={}
for _,obj in workspace:GetDescendants() do
 if string.find(string.lower(obj.Name),'sakura',1,true) then
  local parts={};local scripts={}
  if obj:IsA('BasePart') then table.insert(parts,{name=obj.Name,class=obj.ClassName,size=tostring(obj.Size)}) end
  for _,p in obj:GetDescendants() do
   if p:IsA('BasePart') then table.insert(parts,{name=p.Name,class=p.ClassName,size=tostring(p.Size)}) end
   if p:IsA('LuaSourceContainer') then table.insert(scripts,p:GetFullName()) end
  end
  table.insert(results,{path=obj:GetFullName(),class=obj.ClassName,parts=parts,scripts=scripts})
 end
end
return game:GetService('HttpService'):JSONEncode(results)
