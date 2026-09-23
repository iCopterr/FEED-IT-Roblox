-- Editor-only art recipe; no runtime generator or animation controller.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local bunny=assert(workspace:FindFirstChild("HornedBunny_RigTest"),"Bunny missing")
assert(not workspace:FindFirstChild("Fox_RigTest"),"Fox already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="Fox_RigTest"
m:SetAttribute("Purpose","Standalone fox art and rig trial")
local orange=Color3.fromRGB(205,99,39)
local light=Color3.fromRGB(236,140,65)
local rust=Color3.fromRGB(157,65,30)
local white=Color3.fromRGB(255,239,209)
local dark=Color3.fromRGB(47,32,28)
local pink=Color3.fromRGB(178,108,93)
local function part(n,size,cf,color,class)
    local p=Instance.new(class or "Part")
    p.Name,p.Size,p.CFrame,p.Color=n,size,cf,color
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Parent=m
    return p
end
local function detail(n,size,cf,color,limb,class)
    local p=part(n,size,cf,color,class)
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local torso=part("Torso",V(1.8,1.6,2.65),CF(0,1.74,.23),orange)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,orange)
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
detail("BackSlope",V(1.81,.43,2.2),CF(0,2.51,.47)*CFrame.Angles(0,math.pi,0),light,torso,"WedgePart")
detail("ChestRuff",V(1.39,1.32,.53),CF(0,1.83,-1.11),white,torso,"WedgePart")
detail("Belly",V(1.3,.22,1.82),CF(0,.98,.06),white,torso)
local head=limb("Head",V(1.67,1.4,1.33),CF(0,2.46,-1.59),orange,V(0,2.4,-.96))
detail("Forehead",V(1.5,.36,1.13),CF(0,3.12,-1.64),light,head,"WedgePart")
detail("MuzzleBase",V(1.12,.49,.88),CF(0,2.16,-2.46),white,head)
detail("MuzzleTaper",V(.76,.46,.82),CF(0,2.18,-2.86)*CFrame.Angles(0,math.pi,0),white,head,"WedgePart")
detail("Nose",V(.43,.28,.27),CF(0,2.28,-3.22),dark,head)
detail("NoseGlint",V(.13,.04,.018),CF(-.09,2.37,-3.36),white,head)
detail("Mouth",V(.42,.045,.035),CF(0,1.96,-2.91),dark,head)
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    detail(side.."CheekRuff",V(.42,.69,1.18),CF(s*.85,2.11,-1.84)*CFrame.Angles(0,s*math.rad(12),0),white,head,"WedgePart")
    detail(side.."Eye",V(.085,.26,.34),CF(s*.847,2.66,-1.97),dark,head)
    detail(side.."EyeGlint",V(.022,.075,.08),CF(s*.9,2.73,-2.055),white,head)
    detail(side.."Brow",V(.13,.11,.45),CF(s*.858,2.85,-1.98)*CFrame.Angles(math.rad(-9),0,0),rust,head)
    local ear=limb(side.."Ear",V(.61,1.1,.44),CF(s*.55,3.55,-1.39)*CFrame.Angles(math.rad(-7),0,-s*math.rad(9)),dark,V(s*.48,3.02,-1.37),"WedgePart")
    detail(side.."EarFur",V(.48,.85,.2),ear.CFrame*CF(0,-.08,-.15),orange,ear,"WedgePart")
    detail(side.."InnerEar",V(.29,.6,.035),ear.CFrame*CF(0,-.12,-.27),pink,ear,"WedgePart")
    for _,front in {true,false} do
        local z=front and -.67 or 1.11
        local n=side..(front and "FrontLeg" or "HindLeg")
        local leg=limb(n,V(.43,1.07,.48),CF(s*.64,.72,z),orange,V(s*.64,1.16,z))
        detail(n.."Sock",V(.45,.49,.5),CF(s*.64,.4,z),dark,leg)
        detail(n.."Paw",V(.54,.31,.75),CF(s*.64,.225,z-.17),dark,leg)
        if not front then detail(n.."Haunch",V(.6,.73,.82),CF(s*.73,1.18,z),rust,leg,"WedgePart") end
    end
end
local tail=limb("Tail",V(.65,.7,1.0),CF(0,1.75,1.87)*CFrame.Angles(math.rad(-20),0,0),rust,V(0,1.77,1.49))
detail("TailFull",V(1.19,1.2,2.05),CF(.22,2.13,2.83)*CFrame.Angles(math.rad(-21),math.rad(12),0),orange,tail)
detail("TailTopFur",V(1.22,.44,1.77),CF(.22,2.75,2.75)*CFrame.Angles(math.rad(-21),math.rad(12),0),light,tail,"WedgePart")
detail("WhiteTailTip",V(1.05,1.04,1.49),CF(.58,2.64,4.07)*CFrame.Angles(math.rad(-21),math.rad(12),0),white,tail,"WedgePart")
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
local bp=bunny:GetPivot()
local previous=workspace:FindFirstChild("Boar_RigTest")
local direction=1
if previous and bp:PointToObjectSpace(previous:GetPivot().Position).X>0 then direction=-1 end
local pos=bp.Position+bp.RightVector*6*direction
local ground=bunny.PrimaryPart.Position.Y-bunny.PrimaryPart.Size.Y/2-bunny.Humanoid.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*bp.Rotation)
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("BuildFox","Build fox beside horned bunny")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=(m:GetPivot().Position+bp.Position)/2+V(0,.8,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(8,6,-13),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),m:GetPivot().Position)
