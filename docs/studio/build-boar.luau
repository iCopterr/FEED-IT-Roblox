-- Editor-only recipe: creates a standalone rig to the chicken's local left.
assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
local chicken=assert(workspace:FindFirstChild("Chicken_RigTest"),"Chicken missing")
assert(not workspace:FindFirstChild("Boar_RigTest"),"Boar already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="Boar_RigTest"
m:SetAttribute("Purpose","Standalone boar art and rig trial")
local brown=Color3.fromRGB(111,74,51)
local light=Color3.fromRGB(146,101,69)
local dark=Color3.fromRGB(57,39,32)
local hoof=Color3.fromRGB(38,31,29)
local ivory=Color3.fromRGB(250,232,187)
local pink=Color3.fromRGB(159,107,87)
local function p(n,size,cf,c,class)
    local o=Instance.new(class or "Part")
    o.Name,o.Size,o.CFrame,o.Color=n,size,cf,c
    o.Material=Enum.Material.SmoothPlastic
    o.TopSurface,o.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    o.Anchored,o.CanCollide,o.Massless=true,false,true
    o.Parent=m
    return o
end
local function detail(n,size,cf,c,limb,class)
    local o=p(n,size,cf,c,class)
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,o,o
    return o
end
local torso=p("Torso",V(2.7,2.2,3.5),CF(0,1.98,.25),brown)
torso.CanCollide,torso.Massless=true,false
local root=p("HumanoidRootPart",torso.Size,torso.CFrame,brown)
root.Transparency,root.RootPriority,root.Massless=1,127,false
m.PrimaryPart=root
local function joint(name,a,b,at)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=name,a,b
    j.C0,j.C1=a.CFrame:ToObjectSpace(CF(at)),b.CFrame:ToObjectSpace(CF(at))
    j.Parent=a
end
joint("RootJoint",root,torso,root.Position)
local function limb(n,size,cf,c,anchor,class)
    local o=p(n,size,cf,c,class)
    joint("TorsoTo"..n,torso,o,anchor)
    return o
end
detail("ShoulderMantle",V(2.9,.8,2.0),CF(0,2.87,-.35)*CFrame.Angles(math.rad(8),0,0),light,torso,"WedgePart")
detail("RumpSlope",V(2.55,.66,1.8),CF(0,2.75,1.13)*CFrame.Angles(0,math.pi,0),brown,torso,"WedgePart")
local head=limb("Head",V(2.12,1.66,1.75),CF(0,1.98,-2),brown,V(0,2.45,-1.4))
detail("Forehead",V(1.85,.57,1.4),CF(0,2.78,-2.03),light,head,"WedgePart")
detail("Muzzle",V(1.46,.95,1.05),CF(0,1.58,-3.08),light,head)
detail("Snout",V(1.48,.78,.22),CF(0,1.61,-3.68),pink,head)
detail("LowerJaw",V(1.24,.31,.92),CF(0,1.09,-3.04),dark,head)
for _,s in {-1,1} do
    local name=s==-1 and "Left" or "Right"
    detail(name.."Nostril",V(.24,.16,.035),CF(s*.38,1.65,-3.8),hoof,head)
    detail(name.."Eye",V(.075,.24,.29),CF(s*1.08,2.32,-2.4),hoof,head)
    detail(name.."EyeGlint",V(.025,.065,.065),CF(s*1.13,2.38,-2.48),ivory,head)
    detail(name.."Brow",V(.22,.18,.65),CF(s*1.06,2.53,-2.34)*CFrame.Angles(math.rad(-12),0,0),dark,head)
    local ear=detail(name.."Ear",V(.55,.84,.38),CF(s*.85,3.05,-1.59)*CFrame.Angles(math.rad(-16),0,-s*math.rad(23)),brown,head,"WedgePart")
    detail(name.."InnerEar",V(.29,.49,.065),ear.CFrame*CF(0,.025,-.22),pink,head,"WedgePart")
    local a,b=V(s*.71,1.3,-3.08),V(s*1.19,1.47,-3.42)
    detail(name.."TuskBase",V(.26,.26,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),ivory,head)
    detail(name.."TuskTip",V(.22,.88,.32),CF(s*1.2,1.85,-3.4)*CFrame.Angles(math.rad(-12),0,-s*math.rad(9)),ivory,head,"WedgePart")
    for _,front in {true,false} do
        local z=front and -.87 or 1.34
        local n=name..(front and "FrontLeg" or "HindLeg")
        local leg=limb(n,V(.65,.95,.74),CF(s*.94,.64,z),brown,V(s*.94,.93,z))
        detail(n.."Hoof",V(.72,.34,.85),CF(s*.94,.21,z-.08),hoof,leg)
        detail(n.."HoofSplit",V(.045,.21,.032),CF(s*.94,.18,z-.52),light,leg)
    end
    for i=1,3 do detail(name.."Fur"..i,V(.17,.53,.56),CF(s*1.39,2.25,-.4+(i-1)*.65),light,torso,"WedgePart") end
end
for i=1,8 do
    detail("ManeBristle"..i,V(.31,.42+(i<=3 and .2 or 0),.5),CF(0,3.13,-1.05+(i-1)*.39)*CFrame.Angles(math.rad(14),0,0),dark,torso,"WedgePart")
end
local tail=limb("Tail",V(.2,.2,.61),CF(0,2.22,2.24)*CFrame.Angles(math.rad(-20),0,0),dark,V(0,2.18,2.0))
detail("TailCurlUp",V(.2,.48,.2),CF(0,2.48,2.52),dark,tail)
detail("TailCurlTip",V(.2,.19,.37),CF(0,2.73,2.42),dark,tail)
local h=Instance.new("Humanoid")
h.RigType=Enum.HumanoidRigType.R15
h.RequiresNeck,h.BreakJointsOnDeath=false,false
h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
h.Parent=m
Instance.new("Animator",h)
local low=math.huge
for _,o in m:GetChildren() do if o:IsA("BasePart") and o.Transparency<1 then
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        low=math.min(low,(o.CFrame*V(x*o.Size.X/2,y*o.Size.Y/2,z*o.Size.Z/2)).Y)
    end end end
end end
h.HipHeight=root.Position.Y-root.Size.Y/2-low+.025
local cp=chicken:GetPivot()
local pos=cp.Position-cp.RightVector*7
-- Match the chicken's standing plane: nearby display models may be above it.
local ch=assert(chicken:FindFirstChildOfClass("Humanoid"),"Chicken Humanoid missing")
local ground=chicken.PrimaryPart.Position.Y-chicken.PrimaryPart.Size.Y/2-ch.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*cp.Rotation)
for _,o in m:GetChildren() do if o:IsA("BasePart") then o.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("BuildBoar","Build boar left of chicken")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=(m:GetPivot().Position+cp.Position)/2+V(0,.7,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+cp.RightVector*8+V(0,6,0)+cp.LookVector*13,focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),"position",m:GetPivot().Position,"left offset",cp:PointToObjectSpace(m:GetPivot().Position))
