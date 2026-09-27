-- EDITOR ONLY, read-only audit. Does not upload or install any asset.
assert(not game:GetService("RunService"):IsRunning(), "Edit mode required")
local sections = {
 {"Torso",74737247690802,2884},
 {"Neck",85272560657968,336},
 {"LeftHindleg",98257052321600,204},
 {"RightWing",94690905362066,122},
 {"LeftWing",127737090142843,122},
 {"RightForeleg",109580473461278,204},
 {"RightHindleg",127753218973786,204},
 {"Skull",120536135390190,408},
 {"Tail",123119926804895,266},
 {"LeftForeleg",74381654615827,204},
}
local rows = {}
local passed = true
for _,section in sections do
 local ok,result = pcall(function()
  local mesh = game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri("rbxassetid://"..section[2]))
  local row = {Name=section[1], AssetId=section[2], ExpectedFaces=section[3], Faces=#mesh:GetFaces(), Size=tostring(mesh:GetSize())}
  mesh:Destroy()
  row.Passed = row.Faces == row.ExpectedFaces
  return row
 end)
 if not ok then result = {Name=section[1], AssetId=section[2], Passed=false, Error=tostring(result)} end
 if not result.Passed then passed = false end
 table.insert(rows,result)
end
print(game:GetService("HttpService"):JSONEncode({Passed=passed,Sections=rows}))
-- Passing this audit alone is insufficient: inspect colors, silhouette, rig,
-- scaling, serialization and real carry/place/feed behavior before installing.
