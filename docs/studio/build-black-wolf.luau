-- Editor-only standalone art recipe. No animation or runtime generator.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local fox=assert(workspace:FindFirstChild("Fox_RigTest"),"Fox missing")
assert(not workspace:FindFirstChild("BlackWolf_RigTest"),"Wolf already exists")
local V,CF=Vector3.new,CFrame.new
local m=Instance.new("Model")
m.Name="BlackWolf_RigTest"
m:SetAttribute("Purpose","Standalone black wolf art and rig trial")
local coat=Color3.fromRGB(34,39,47)
local ridge=Color3.fromRGB(55,63,75)
local black=Color3.fromRGB(17,21,27)
local grey=Color3.fromRGB(85,94,106)
local amber=Color3.fromRGB(244,187,67)
local ivory=Color3.fromRGB(227,222,204)
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
local torso=part("Torso",V(2.15,2.0,3.25),CF(0,2.25,.3),coat)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,coat)
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
detail("ShoulderMantle",V(2.35,.83,1.92),CF(0,3.13,-.45),ridge,torso,"WedgePart")
detail("RumpSlope",V(2.04,.51,1.72),CF(0,3.08,1.04)*CFrame.Angles(0,math.pi,0),coat,torso,"WedgePart")
detail("ChestRuff",V(1.65,1.72,.64),CF(0,2.5,-1.4),ridge,torso,"WedgePart")
detail("ChestPatch",V(.77,1.11,.13),CF(0,2.49,-1.74),grey,torso,"WedgePart")
local head=limb("Head",V(1.91,1.59,1.62),CF(0,3.01,-1.95),coat,V(0,3.04,-1.16))
detail("Forehead",V(1.73,.35,1.45),CF(0,3.76,-2.0),ridge,head,"WedgePart")
detail("Muzzle",V(1.14,.66,1.22),CF(0,2.73,-3.13),ridge,head)
detail("MuzzleBridge",V(.94,.29,.94),CF(0,3.09,-3.03)*CFrame.Angles(0,math.pi,0),coat,head,"WedgePart")
detail("Nose",V(.73,.4,.24),CF(0,2.84,-3.84),black,head)
detail("NoseGlint",V(.23,.045,.02),CF(-.16,2.99,-3.971),grey,head)
detail("LowerJaw",V(.96,.25,1.05),CF(0,2.27,-3.06),coat,head)
detail("MouthLine",V(1.0,.08,.92),CF(0,2.43,-3.12),black,head)
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    detail(side.."EyeSocket",V(.08,.37,.53),CF(s*.975,3.2,-2.37),black,head)
    detail(side.."Eye",V(.105,.18,.33),CF(s*1.015,3.21,-2.42),amber,head)
    detail(side.."Pupil",V(.025,.17,.075),CF(s*1.08,3.21,-2.46),black,head)
    detail(side.."EyeGlint",V(.025,.052,.06),CF(s*1.087,3.26,-2.53),ivory,head)
    detail(side.."Brow",V(.2,.16,.67),CF(s*.98,3.43,-2.34)*CFrame.Angles(math.rad(-12),0,0),ridge,head)
    detail(side.."CheekFur",V(.5,.94,1.28),CF(s*.94,2.76,-1.87)*CFrame.Angles(0,s*math.rad(13),0),ridge,head,"WedgePart")
    detail(side.."Fang",V(.12,.24,.18),CF(s*.42,2.38,-3.43),ivory,head,"WedgePart")
    local ear=limb(side.."Ear",V(.67,1.13,.53),CF(s*.6,4.04,-1.7)*CFrame.Angles(math.rad(-8),0,-s*math.rad(8)),coat,V(s*.53,3.64,-1.63),"WedgePart")
    detail(side.."EarRim",V(.5,.84,.16),ear.CFrame*CF(0,-.05,-.22),ridge,ear,"WedgePart")
    detail(side.."InnerEar",V(.28,.55,.035),ear.CFrame*CF(0,-.12,-.32),black,ear,"WedgePart")
    for i=1,3 do
        detail(side.."Mane"..i,V(.38,.97-i*.12,.8),CF(s*1.12,2.94,-.92+(i-1)*.57)*CFrame.Angles(0,0,s*math.rad(13)),i%2==0 and coat or ridge,torso,"WedgePart")
    end
    for _,front in {true,false} do
        local z=front and -.82 or 1.4
        local n=side..(front and "FrontLeg" or "HindLeg")
        local leg=limb(n,V(.54,1.4,.63),CF(s*.76,.99,z),coat,V(s*.76,1.65,z))
        detail(n.."Ankle",V(.5,.58,.55),CF(s*.76,.51,z-.06),black,leg)
        detail(n.."Paw",V(.72,.38,.99),CF(s*.76,.255,z-.27),black,leg)
        if not front then detail(n.."Haunch",V(.86,1.07,1.12),CF(s*.88,1.58,z-.02),ridge,leg,"WedgePart") end
        for i=-1,1,2 do detail(n.."Toe"..i,V(.035,.085,.28),CF(s*.76+i*.19,.4,z-.56),ridge,leg) end
    end
end
for i=1,5 do detail("BackFur"..i,V(.48,.39,.65),CF(0,3.4,-.73+(i-1)*.55)*CFrame.Angles(math.rad(12),0,0),black,torso,"WedgePart") end
local tail=limb("Tail",V(.72,.77,1.05),CF(0,2.13,2.16)*CFrame.Angles(math.rad(18),0,0),coat,V(0,2.32,1.77))
detail("BushyTail",V(.97,.99,1.84),CF(.15,1.68,3.24)*CFrame.Angles(math.rad(23),math.rad(10),0),ridge,tail)
detail("TailFur",V(1.0,.42,1.68),CF(.15,2.18,3.12)*CFrame.Angles(math.rad(23),math.rad(10),0),coat,tail,"WedgePart")
detail("TailTip",V(.76,.8,1.2),CF(.39,1.12,4.39)*CFrame.Angles(math.rad(23),math.rad(10),0),black,tail,"WedgePart")
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
local fp=fox:GetPivot()
local previous=workspace:FindFirstChild("HornedBunny_RigTest")
local direction=1
if previous and fp:PointToObjectSpace(previous:GetPivot().Position).X>0 then direction=-1 end
local pos=fp.Position+fp.RightVector*6*direction
local ground=fox.PrimaryPart.Position.Y-fox.PrimaryPart.Size.Y/2-fox.Humanoid.HipHeight
m:PivotTo(CF(pos.X,ground+root.Size.Y/2+h.HipHeight,pos.Z)*fp.Rotation)
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("BuildBlackWolf","Build black wolf beside fox")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=(m:GetPivot().Position+fp.Position)/2+V(0,1,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(8,6,-13),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),m:GetPivot().Position)
