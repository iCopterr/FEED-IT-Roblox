-- Editor-only art recipe, outside Rojo runtime mappings.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local boar=assert(workspace:FindFirstChild("Boar_RigTest"),"Boar missing")
assert(not workspace:FindFirstChild("HornedBunny_RigTest"),"Bunny already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="HornedBunny_RigTest"
m:SetAttribute("Purpose","Standalone horned bunny art and rig trial")
local cream=Color3.fromRGB(235,222,199)
local white=Color3.fromRGB(255,246,229)
local tan=Color3.fromRGB(188,156,122)
local pink=Color3.fromRGB(215,152,147)
local brown=Color3.fromRGB(110,76,51)
local dark=Color3.fromRGB(42,31,32)
local function part(n,size,cf,color)
    local p=Instance.new("Part")
    p.Name,p.Size,p.CFrame,p.Color=n,size,cf,color
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Parent=m
    return p
end
local function detail(n,size,cf,color,limb,ball)
    local p=part(n,size,cf,color)
    if ball then p.Shape=Enum.PartType.Ball end
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local torso=part("Torso",V(1.9,1.9,2.2),CF(0,1.45,.23),cream)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,cream)
root.Transparency,root.RootPriority,root.Massless=1,127,false
m.PrimaryPart=root
local function joint(n,a,b,at)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=n,a,b
    j.C0,j.C1=a.CFrame:ToObjectSpace(CF(at)),b.CFrame:ToObjectSpace(CF(at))
    j.Parent=a
end
joint("RootJoint",root,torso,root.Position)
local function limb(n,size,cf,color,at)
    local p=part(n,size,cf,color)
    joint("TorsoTo"..n,torso,p,at)
    return p
end
detail("RumpFluff",V(2.06,1.9,2.25),CF(0,1.52,.49),cream,torso,true)
detail("ChestBib",V(1.26,1.48,.28),CF(0,1.52,-.92),white,torso,true)
local head=limb("Head",V(1.7,1.5,1.48),CF(0,2.38,-1.01),cream,V(0,2.25,-.65))
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    detail(side.."Cheek",V(.72,.57,.37),CF(s*.35,2.04,-1.8),white,head,true)
    detail(side.."Eye",V(.13,.36,.36),CF(s*.865,2.54,-1.34),dark,head,true)
    detail(side.."EyeGlint",V(.035,.1,.105),CF(s*.939,2.64,-1.42),white,head)
    detail(side.."CheekBlush",V(.06,.15,.28),CF(s*.89,2.18,-1.42),pink,head,true)
    local ear=limb(side.."Ear",V(.51,1.97,.46),CF(s*.52,3.93,-.92)*CFrame.Angles(math.rad(-8),0,-s*math.rad(12)),cream,V(s*.38,2.97,-.82))
    detail(side.."EarTip",V(.5,.43,.45),ear.CFrame*CF(0,.92,0),cream,ear,true)
    detail(side.."InnerEar",V(.27,1.5,.045),ear.CFrame*CF(0,.04,-.25),pink,ear)
    local a,b,c=V(s*.71,2.97,-.45),V(s*1.12,3.68,-.23),V(s*1.4,4.3,-.42)
    local function horn(n,x,y,width,col)
        detail(side..n,V(width,width,(y-x).Magnitude),CFrame.lookAt((x+y)/2,y),col,head)
    end
    horn("AntlerBase",a,b,.22,brown)
    horn("AntlerTip",b,c,.13,tan)
    horn("AntlerBranch",b,V(s*1.65,3.96,-.06),.12,tan)
    detail(side.."HornRoot",V(.34,.23,.34),CF(a),tan,head,true)
    local fore=limb(side.."FrontLeg",V(.43,.76,.48),CF(s*.59,.64,-.66),cream,V(s*.59,1.03,-.65))
    detail(side.."FrontPaw",V(.56,.31,.78),CF(s*.59,.26,-.91),white,fore,true)
    local hind=limb(side.."HindLeg",V(.72,.93,.95),CF(s*.86,.73,.82),tan,V(s*.76,1.15,.72))
    detail(side.."Haunch",V(.92,1.15,1.13),CF(s*.91,.99,.71),cream,hind,true)
    detail(side.."LongHindPaw",V(.78,.36,1.38),CF(s*.91,.26,.39),white,hind,true)
    for i=-1,1,2 do
        detail(side.."ToeMark"..i,V(.035,.075,.21),CF(s*.91+i*.17,.41,-.07),tan,hind)
    end
end
detail("Nose",V(.22,.16,.13),CF(0,2.2,-2.02)*CFrame.Angles(0,0,math.rad(45)),pink,head)
detail("Mouth",V(.035,.16,.035),CF(0,2.02,-1.996),dark,head)
detail("BuckTeeth",V(.24,.2,.07),CF(0,1.91,-1.98),white,head)
detail("ToothSplit",V(.018,.13,.012),CF(0,1.9,-2.02),tan,head)
local tail=limb("Tail",V(.85,.85,.85),CF(0,1.42,1.7),white,V(0,1.45,1.28))
tail.Shape=Enum.PartType.Ball
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
local bp=boar:GetPivot()
local chicken=workspace:FindFirstChild("Chicken_RigTest")
local direction=1
if chicken and bp:PointToObjectSpace(chicken:GetPivot().Position).X>0 then direction=-1 end
local pos=bp.Position+bp.RightVector*6*direction
local ground=boar.PrimaryPart.Position.Y-boar.PrimaryPart.Size.Y/2-boar.Humanoid.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*bp.Rotation)
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("HornedBunny","Build horned bunny beside boar")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=(m:GetPivot().Position+bp.Position)/2+V(0,1,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(8,6,-13),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),m:GetPivot().Position)
