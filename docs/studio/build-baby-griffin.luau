-- Editor-only art recipe; no gameplay or animation scripts.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local wolf=assert(workspace:FindFirstChild("BlackWolf_RigTest"),"Wolf missing")
assert(not workspace:FindFirstChild("BabyGriffin_RigTest"),"Griffin already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="BabyGriffin_RigTest"
m:SetAttribute("Purpose","Standalone baby griffin art and rig trial")
local tan=Color3.fromRGB(191,137,70)
local gold=Color3.fromRGB(239,179,66)
local cream=Color3.fromRGB(242,231,207)
local white=Color3.fromRGB(255,249,232)
local brown=Color3.fromRGB(117,76,43)
local feather=Color3.fromRGB(205,187,151)
local dark=Color3.fromRGB(40,32,29)
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
local torso=part("Torso",V(1.95,1.7,2.35),CF(0,1.58,.27),tan)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,tan)
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
detail("ChestDown",V(1.63,1.61,.48),CF(0,1.89,-.91),cream,torso,"WedgePart")
detail("Belly",V(1.44,.25,1.65),CF(0,.8,.06),cream,torso)
detail("BackFeathers",V(1.92,.41,1.7),CF(0,2.38,.12),feather,torso,"WedgePart")
local head=limb("Head",V(1.9,1.7,1.52),CF(0,2.58,-1.22),white,V(0,2.35,-.73))
detail("BeakBase",V(.83,.55,.74),CF(0,2.4,-2.27),gold,head)
detail("BeakHook",V(.65,.68,.38),CF(0,2.22,-2.7)*CFrame.Angles(0,math.pi,0),gold,head,"WedgePart")
detail("BeakLower",V(.61,.19,.58),CF(0,2.07,-2.26),brown,head)
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    detail(side.."EyePatch",V(.11,.64,.64),CF(s*.966,2.76,-1.62),feather,head)
    detail(side.."Eye",V(.13,.4,.4),CF(s*1.032,2.77,-1.69),dark,head)
    detail(side.."EyeGlint",V(.025,.12,.11),CF(s*1.107,2.89,-1.8),white,head)
    detail(side.."BrowFeather",V(.23,.2,.74),CF(s*.94,3.16,-1.52)*CFrame.Angles(math.rad(-8),0,0),cream,head)
    detail(side.."CheekFeather",V(.28,.79,.96),CF(s*.9,2.3,-1.02)*CFrame.Angles(0,0,s*math.rad(12)),cream,head,"WedgePart")
    detail(side.."Crest",V(.36,.71,.51),CF(s*.52,3.62,-.85)*CFrame.Angles(math.rad(-20),0,-s*math.rad(13)),white,head,"WedgePart")
    local fore=limb(side.."FrontLeg",V(.4,.85,.46),CF(s*.65,.66,-.62),gold,V(s*.65,.96,-.58))
    detail(side.."ForelegDown",V(.56,.46,.62),CF(s*.65,1.03,-.61),cream,fore,"WedgePart")
    detail(side.."FrontFoot",V(.56,.24,.62),CF(s*.65,.22,-.78),gold,fore)
    for i=1,3 do
        detail(side.."Talon"..i,V(.13,.15,.46),CF(s*.65+(i-2)*.2,.18,-1.15),brown,fore,"WedgePart")
    end
    local hind=limb(side.."HindLeg",V(.59,.83,.74),CF(s*.71,.66,1.0),tan,V(s*.7,1.01,1.0))
    detail(side.."Haunch",V(.81,.91,.99),CF(s*.8,1.11,.94),tan,hind,"WedgePart")
    detail(side.."HindPaw",V(.69,.33,.89),CF(s*.73,.255,.82),cream,hind)
    for i=-1,1,2 do detail(side.."Toe"..i,V(.026,.08,.2),CF(s*.73+i*.16,.39,.52),brown,hind) end
    local wing=limb(side.."Wing",V(.49,.76,1.23),CF(s*1.14,2.19,.17)*CFrame.Angles(0,0,-s*math.rad(18)),cream,V(s*.97,2.24,-.2))
    for i=1,5 do
        detail(side.."FlightFeather"..i,V(.37,.2,1.3+(i-1)*.12),CF(s*(1.35+i*.2),2.37+i*.11,.62+i*.15)*CFrame.Angles(math.rad(-12),s*math.rad(15+i*4),s*math.rad(7)),i%2==0 and cream or white,wing,"WedgePart")
    end
    for i=1,3 do
        detail(side.."WingCover"..i,V(.4,.25,.83),CF(s*(1.3+i*.23),2.55+i*.1,.12+i*.12)*CFrame.Angles(0,s*math.rad(24),0),feather,wing,"WedgePart")
    end
end
for i=1,3 do detail("BibFeather"..i,V(.35,.47,.17),CF((i-2)*.43,1.58,-1.18),white,torso,"WedgePart") end
local tail=limb("Tail",V(.23,.23,.96),CF(0,1.46,1.8)*CFrame.Angles(math.rad(-16),0,0),tan,V(0,1.42,1.39))
detail("TailCurve",V(.23,.23,.9),CF(.22,1.77,2.59)*CFrame.Angles(math.rad(-25),math.rad(27),0),tan,tail)
detail("TailTuft",V(.59,.57,.88),CF(.46,2.02,3.16)*CFrame.Angles(math.rad(-25),math.rad(27),0),brown,tail,"WedgePart")
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
local wp=wolf:GetPivot()
local previous=workspace:FindFirstChild("Fox_RigTest")
local direction=1
if previous and wp:PointToObjectSpace(previous:GetPivot().Position).X>0 then direction=-1 end
local pos=wp.Position+wp.RightVector*7*direction
local ground=wolf.PrimaryPart.Position.Y-wolf.PrimaryPart.Size.Y/2-wolf.Humanoid.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*wp.Rotation)
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("BabyGriffin","Build baby griffin beside wolf")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=(m:GetPivot().Position+wp.Position)/2+V(0,1,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(8,6,-13),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),m:GetPivot().Position)
