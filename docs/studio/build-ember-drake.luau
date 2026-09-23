-- Editor-only standalone art recipe; no animation or gameplay integration.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local neighbor=assert(workspace:FindFirstChild("BabyGriffin_RigTest"),"Griffin missing")
assert(not workspace:FindFirstChild("EmberDrake_RigTest"),"Drake already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="EmberDrake_RigTest"
m:SetAttribute("Purpose","Standalone ember drake art and rig trial")
local coal=Color3.fromRGB(46,37,39)
local slate=Color3.fromRGB(75,49,46)
local dark=Color3.fromRGB(25,23,28)
local red=Color3.fromRGB(163,50,29)
local fire=Color3.fromRGB(255,120,31)
local gold=Color3.fromRGB(255,191,70)
local bone=Color3.fromRGB(206,171,125)
local function part(n,size,cf,color,class)
    local p=Instance.new(class or "Part")
    p.Name,p.Size,p.CFrame,p.Color=n,size,cf,color
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Parent=m
    return p
end
local function detail(n,size,cf,color,limb,class,glow)
    local p=part(n,size,cf,color,class)
    if glow then p.Material=Enum.Material.Neon end
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local function beam(n,a,b,width,color,limb,glow)
    return detail(n,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,limb,nil,glow)
end
local torso=part("Torso",V(2.2,1.9,3.15),CF(0,1.97,.15),coal)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,coal)
root.Transparency,root.RootPriority,root.Massless=1,127,false
m.PrimaryPart=root
local function joint(n,a,b,at)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=n,a,b
    j.C0,j.C1=a.CFrame:ToObjectSpace(CF(at)),b.CFrame:ToObjectSpace(CF(at))
    j.Parent=a
end
joint("RootJoint",root,torso,root.Position)
local function limb(n,size,cf,color,at,class)
    local p=part(n,size,cf,color,class)
    joint("TorsoTo"..n,torso,p,at)
    return p
end
detail("ShoulderArmor",V(2.3,.66,1.7),CF(0,2.87,-.6),slate,torso,"WedgePart")
detail("RumpArmor",V(2.05,.43,1.4),CF(0,2.81,1.04)*CFrame.Angles(0,math.pi,0),slate,torso,"WedgePart")
for i=1,3 do detail("ChestPlate"..i,V(1.29-i*.12,.35,.16),CF(0,2.53-(i-1)*.39,-1.46),red,torso) end
local head=limb("Head",V(1.78,1.46,1.56),CF(0,3.04,-1.88),slate,V(0,2.72,-1.21))
detail("Muzzle",V(1.42,.65,1.17),CF(0,2.75,-3.04),coal,head)
detail("NoseRidge",V(1.2,.35,1.09),CF(0,3.21,-2.9)*CFrame.Angles(0,math.pi,0),slate,head,"WedgePart")
detail("Jaw",V(1.25,.25,1.12),CF(0,2.28,-2.99),dark,head)
local function triangle(n,a,b,c,color,limb)
    local ab,ac,bc=b-a,c-a,c-b
    if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
    elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
    ab,ac,bc=b-a,c-a,c-b
    local right,back=ac:Cross(ab).Unit,bc.Unit
    local up=bc:Cross(right).Unit
    local h=math.abs(ab:Dot(up))
    detail(n.."A",V(.1,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),color,limb,"WedgePart")
    detail(n.."B",V(.1,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),color,limb,"WedgePart")
end
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    detail(side.."EyeSocket",V(.11,.43,.64),CF(s*.916,3.25,-2.21),dark,head)
    detail(side.."Eye",V(.13,.21,.4),CF(s*.98,3.25,-2.29),gold,head,nil,true)
    detail(side.."Pupil",V(.026,.19,.075),CF(s*1.06,3.25,-2.33),dark,head)
    detail(side.."Brow",V(.26,.18,.77),CF(s*.94,3.49,-2.17)*CFrame.Angles(math.rad(-13),0,0),coal,head)
    detail(side.."Nostril",V(.21,.12,.035),CF(s*.43,2.93,-3.64),dark,head)
    detail(side.."Fang",V(.16,.34,.23),CF(s*.51,2.41,-3.37),bone,head,"WedgePart")
    beam(side.."HornBase",V(s*.56,3.66,-1.37),V(s*.85,4.15,-.85),.33,dark,head)
    detail(side.."HornTip",V(.24,.83,.37),CF(s*.94,4.33,-.57)*CFrame.Angles(math.rad(29),0,-s*math.rad(15)),bone,head,"WedgePart")
    detail(side.."CheekSpike",V(.35,.64,.79),CF(s*.95,2.86,-1.32)*CFrame.Angles(math.rad(-25),0,s*math.rad(15)),coal,head,"WedgePart")
    for i=1,3 do
        beam(side.."CheekEmber"..i,V(s*.91,3.0-i*.14,-1.98),V(s*.93,2.91-i*.14,-1.7),.04,fire,head,true)
        detail(side.."FlankScale"..i,V(.19,.65,.71),CF(s*1.15,2.18,-.43+(i-1)*.77),slate,torso,"WedgePart")
        beam(side.."FlankSeam"..i,V(s*1.125,1.81,-.74+(i-1)*.77),V(s*1.125,2.46,-.74+(i-1)*.77),.045,fire,torso,true)
    end
    for _,front in {true,false} do
        local z=front and -.89 or 1.15
        local n=side..(front and "FrontLeg" or "HindLeg")
        local leg=limb(n,V(.62,1.05,.77),CF(s*.86,.77,z),coal,V(s*.85,1.35,z))
        detail(n.."Paw",V(.76,.36,1.02),CF(s*.86,.25,z-.18),slate,leg)
        for i=1,3 do detail(n.."Claw"..i,V(.16,.18,.38),CF(s*.86+(i-2)*.25,.17,z-.82),bone,leg,"WedgePart") end
    end
    local a,b,tip=V(s*1.02,2.8,-.35),V(s*2.31,4.14,.1),V(s*4.27,4.56,1.09)
    local rear,inner=V(s*3.6,2.78,2.54),V(s*1.31,2.44,1.57)
    local wing=limb(side.."Wing",V(.3,.3,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),coal,a)
    triangle(side.."OuterSail",b,tip,rear,red,wing)
    triangle(side.."InnerSail",a,b,inner,Color3.fromRGB(200,73,29),wing)
    triangle(side.."MiddleSail",b,rear,inner,Color3.fromRGB(185,58,26),wing)
    beam(side.."WingEdge",b,tip,.22,coal,wing)
    beam(side.."WingFinger",b,rear,.18,coal,wing)
    beam(side.."WingInnerRib",b,inner,.16,coal,wing)
    beam(side.."HotWingEdge",b+V(0,.1,0),tip+V(0,.07,0),.06,fire,wing,true)
    detail(side.."WingThumb",V(.21,.49,.27),CF(b+V(0,.18,0)),bone,wing,"WedgePart")
end
for i=1,5 do
    detail("BackSpine"..i,V(.38,.65-i*.055,.59),CF(0,3.11,-1.02+(i-1)*.65)*CFrame.Angles(math.rad(12),0,0),i%2==0 and fire or red,torso,"WedgePart",i%2==0)
end
local tail=limb("Tail",V(.91,.79,1.34),CF(0,1.8,2.17)*CFrame.Angles(math.rad(12),0,0),coal,V(0,1.95,1.65))
detail("TailMiddle",V(.65,.55,1.37),CF(.22,1.51,3.24)*CFrame.Angles(0,math.rad(18),0),slate,tail)
detail("TailEnd",V(.39,.37,1.18),CF(.6,1.47,4.27)*CFrame.Angles(math.rad(-12),math.rad(22),0),coal,tail)
detail("EmberTailBlade",V(.7,.9,1.15),CF(.92,1.7,5.07)*CFrame.Angles(0,math.rad(22),0),red,tail,"WedgePart")
detail("TailHotCore",V(.23,.58,.86),CF(.93,1.92,5.09)*CFrame.Angles(0,math.rad(22),0),fire,tail,"WedgePart",true)
local h=Instance.new("Humanoid")
h.RigType=Enum.HumanoidRigType.R15
h.RequiresNeck,h.BreakJointsOnDeath=false,false
h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
h.Parent=m
Instance.new("Animator",h)
local low=math.huge
for _,p in m:GetChildren() do if p:IsA("BasePart") and p.Transparency<1 then
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
    end end end
end end
h.HipHeight=root.Position.Y-root.Size.Y/2-low+.025
local np=neighbor:GetPivot()
local previous=workspace:FindFirstChild("BlackWolf_RigTest")
local direction=1
if previous and np:PointToObjectSpace(previous:GetPivot().Position).X>0 then direction=-1 end
local pos=np.Position+np.RightVector*9*direction
local ground=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*np.Rotation)
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("EmberDrake","Build ember drake beside griffin")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=m:GetPivot().Position+V(0,.8,.6)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(10,6,-14),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),m:GetPivot().Position)
