-- Optional editor showcase; templates remain in ReplicatedStorage.PetsModel.
assert(not game:GetService('RunService'):IsRunning())
local old=game.StarterGui:FindFirstChild('_RosterIndexReview');if old then old:Destroy()end
local review=workspace:FindFirstChild('_ExpansionReview');if review then review:Destroy()end
local folder=workspace:FindFirstChild('DivineCosmicShowcase') or Instance.new('Folder')
folder.Name='DivineCosmicShowcase';folder.Parent=workspace
local names={'Divine Phoenix','Heavenly Kirin','Godly Behemoth','Galaxy Dragon','Cosmic Hydra','World Eater'}
for i,name in names do
 if folder:FindFirstChild(name)then continue end
 local m=game.ReplicatedStorage.PetsModel[name]:Clone();m.Name=name;m.Parent=folder
 local _,s=m:GetBoundingBox();m:ScaleTo(m:GetScale()*13/math.max(s.X,s.Y,s.Z))
 local x=((i-1)%3-1)*21;local z=800+math.floor((i-1)/3)*23
 m:PivotTo(CFrame.new(x,10,z)*CFrame.Angles(0,math.rad(-25),0))
 local cf,size=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,6-(cf.Position.Y-size.Y/2),0))
 local pad=Instance.new('Part');pad.Name=name..'DisplayBase';pad.Size=Vector3.new(18,.3,18);pad.Position=Vector3.new(x,5.8,z);pad.Anchored=true;pad.Material=Enum.Material.SmoothPlastic;pad.Color=Color3.fromRGB(58,65,83);pad.Parent=folder
 local label=Instance.new('BillboardGui');label.Name='Nameplate';label.Size=UDim2.fromOffset(230,34);label.StudsOffsetWorldSpace=Vector3.new(0,3,0);label.AlwaysOnTop=true;label.Parent=pad
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=name;text.Font=Enum.Font.GothamBold;text.TextSize=17;text.TextColor3=Color3.new(1,1,1);text.TextStrokeTransparency=.2;text.Parent=label
end
local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=40
camera.CFrame=CFrame.lookAt(Vector3.new(0,36,730),Vector3.new(0,9,811));camera.Focus=CFrame.new(0,9,811)
game:GetService('Selection'):Set({folder})
return 'Six optimized display models in Workspace.DivineCosmicShowcase'
