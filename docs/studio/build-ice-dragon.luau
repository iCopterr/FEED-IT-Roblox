-- Editor-only Studio MCP recipe; intentionally outside all Rojo runtime mappings.
assert(not game:GetService("RunService"):IsRunning(), "Build in Edit mode")
assert(not workspace:FindFirstChild("IceDragon_RigTest"), "IceDragon_RigTest already exists")
local history = game:GetService("ChangeHistoryService")
local recording = history:TryBeginRecording("BuildIceDragon", "Build blocky ice dragon rig")
local model = Instance.new("Model")
model.Name = "IceDragon_RigTest"
model:SetAttribute("Purpose", "Standalone ice dragon art/rig trial; no inventory integration")
local V = Vector3.new
local frost = Color3.fromRGB(160, 221, 245)
local blue = Color3.fromRGB(70, 148, 207)
local deep = Color3.fromRGB(40, 88, 145)
local white = Color3.fromRGB(235, 252, 255)
local ice = Color3.fromRGB(105, 234, 255)
local dark = Color3.fromRGB(14, 32, 62)
local function part(name, size, cf, color, class)
    local p = Instance.new(class or "Part")
    p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Anchored, p.CanCollide, p.Massless = true, false, true
    p.Parent = model
    return p
end
local function weld(p, limb)
    local w = Instance.new("WeldConstraint")
    w.Name, w.Part0, w.Part1, w.Parent = limb.Name.."To"..p.Name, limb, p, p
    return p
end
local function detail(name, size, cf, color, limb, class)
    return weld(part(name,size,cf,color,class),limb)
end
local function beam(name,a,b,width,color,limb)
    return detail(name,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,limb)
end
local torso = part("Torso",V(2.8,2.4,3.6),CFrame.new(0,2.25,0),frost)
torso.CanCollide, torso.Massless = true, false
local root = part("HumanoidRootPart",torso.Size,torso.CFrame,frost)
root.Transparency, root.RootPriority, root.Massless = 1,127,false
model.PrimaryPart = root
local function joint(limb,anchor)
    local world = torso.CFrame * CFrame.new(anchor)
    local m = Instance.new("Motor6D")
    m.Name, m.Part0, m.Part1 = "TorsoTo"..limb.Name,torso,limb
    m.C0, m.C1 = torso.CFrame:ToObjectSpace(world),limb.CFrame:ToObjectSpace(world)
    m.Parent = torso
end
local rj = Instance.new("Motor6D")
rj.Name, rj.Part0, rj.Part1, rj.Parent = "RootJoint",root,torso,root
rj.C0,rj.C1 = CFrame.identity,CFrame.identity
local head = part("Head",V(2.15,1.65,1.8),CFrame.new(0,3.15,-2.05),frost)
joint(head,V(0,torso.Size.Y/2,-torso.Size.Z*.4))
detail("Muzzle",V(1.8,.75,1.2),CFrame.new(0,2.85,-3.35),frost,head)
detail("LowerJaw",V(1.64,.25,1.18),CFrame.new(0,2.39,-3.32),white,head)
detail("MouthLine",V(1.66,.075,.06),CFrame.new(0,2.56,-3.965),deep,head)
for i=1,3 do
    detail("ChestPlate"..i,V(1.7-i*.12,.42,.16),CFrame.new(0,2.87-(i-1)*.47,-1.84),white,torso)
end
-- Two wedges form each triangular membrane, with geometric bases derived from vertices.
local function triangle(name,a,b,c,limb)
    local ab,ac,bc = b-a,c-a,c-b
    if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
    elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
    ab,ac,bc=b-a,c-a,c-b
    local right=ac:Cross(ab).Unit
    local back=bc.Unit
    local up=bc:Cross(right).Unit
    local height=math.abs(ab:Dot(up))
    detail(name.."A",V(.13,height,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),ice,limb,"WedgePart")
    detail(name.."B",V(.13,height,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),ice,limb,"WedgePart")
end
for _,s in {-1,1} do
    local label=s==-1 and "Left" or "Right"
    detail(label.."EyeSocket",V(.13,.64,.85),CFrame.new(s*1.09,3.28,-2.4),deep,head)
    local eye=detail(label.."Eye",V(.15,.37,.48),CFrame.new(s*1.17,3.26,-2.53),ice,head)
    eye.Material=Enum.Material.Neon
    detail(label.."Pupil",V(.035,.29,.11),CFrame.new(s*1.26,3.26,-2.58),dark,head)
    detail(label.."Brow",V(.27,.2,.91),CFrame.new(s*1.13,3.62,-2.4)*CFrame.Angles(math.rad(-12),0,0),blue,head)
    detail(label.."Nostril",V(.19,.12,.055),CFrame.new(s*.52,3.01,-3.96),deep,head)
    detail(label.."Fang",V(.19,.38,.22),CFrame.new(s*.68,2.5,-3.65),white,head,"WedgePart")
    local hornBase=V(s*.72,3.82,-1.72)
    local hornMid=V(s*1.05,4.57,-1.36)
    beam(label.."HornBase",hornBase,hornMid,.42,blue,head)
    detail(label.."HornTip",V(.29,.8,.38),CFrame.new(s*1.17,4.85,-1.1)*CFrame.Angles(math.rad(26),0,-s*math.rad(17)),white,head,"WedgePart")
    detail(label.."CheekFin",V(.36,.72,.9),CFrame.new(s*1.17,3.02,-1.4)*CFrame.Angles(math.rad(-20),0,s*math.rad(20)),blue,head,"WedgePart")
    for _,front in {true,false} do
        local z=front and -1.13 or 1.13
        local legName=label..(front and "FrontLeg" or "HindLeg")
        local leg=part(legName,V(.8,1.1,.9),CFrame.new(s*1.15,.88,z),blue)
        joint(leg,V(s*torso.Size.X*.4,-torso.Size.Y/2,z))
        detail(legName.."Paw",V(1.01,.42,1.2),CFrame.new(s*1.15,.27,z-.25),frost,leg)
        for i=1,3 do
            detail(legName.."Claw"..i,V(.2,.2,.43),CFrame.new(s*1.15+(i-2)*.3,.18,z-.94),white,leg)
        end
    end
    local shoulder=V(s*1.22,3.02,.05)
    local elbow=V(s*2.75,4.8,.25)
    local tip=V(s*5.25,5.62,.55)
    local rear=V(s*4.35,3.65,2.65)
    local notch=V(s*2.65,3.28,2.0)
    local inner=V(s*1.32,2.94,1.55)
    local wing=part(label.."Wing",V(.4,.4,(elbow-shoulder).Magnitude),CFrame.lookAt((elbow+shoulder)/2,elbow),deep)
    joint(wing,V(s*torso.Size.X/2,torso.Size.Y*.38,0))
    triangle(label.."UpperMembrane",shoulder,elbow,notch,wing)
    triangle(label.."OuterMembrane",elbow,tip,rear,wing)
    triangle(label.."MiddleMembrane",elbow,rear,notch,wing)
    triangle(label.."InnerMembrane",shoulder,notch,inner,wing)
    beam(label.."WingLeadingEdge",elbow,tip,.28,blue,wing)
    beam(label.."WingOuterEdge",tip,rear,.2,white,wing)
    beam(label.."WingFinger",elbow,notch,.2,blue,wing)
    beam(label.."WingRib",elbow,rear,.18,blue,wing)
    detail(label.."WingClaw",V(.25,.62,.32),CFrame.new(elbow+V(0,.27,0)),white,wing,"WedgePart")
end
local tail=part("Tail",V(1.1,.9,1.8),CFrame.new(0,1.94,2.42)*CFrame.Angles(math.rad(12),0,0),blue)
joint(tail,V(0,0,torso.Size.Z/2))
detail("TailMiddle",V(.78,.65,1.65),CFrame.new(.25,1.69,3.72)*CFrame.Angles(0,math.rad(18),0),frost,tail)
detail("TailEnd",V(.45,.43,1.35),CFrame.new(.72,1.7,4.86)*CFrame.Angles(math.rad(-12),math.rad(24),0),blue,tail)
detail("TailCrystal",V(.85,1.05,1.25),CFrame.new(1.03,1.93,5.65)*CFrame.Angles(0,math.rad(24),0),ice,tail,"WedgePart")
for i=1,4 do
    detail("BackCrystal"..i,V(.45,.8-i*.07,.66),CFrame.new(0,3.65,-1.0+(i-1)*.78),i%2==0 and white or ice,torso,"WedgePart")
end
detail("TailSpine",V(.3,.6,.6),CFrame.new(0,2.65,2.55),ice,tail,"WedgePart")
local h=Instance.new("Humanoid")
h.RigType=Enum.HumanoidRigType.R15
h.RequiresNeck=false
h.BreakJointsOnDeath=false
h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
h.WalkSpeed=7
h.Parent=model
Instance.new("Animator",h)
local lowest=math.huge
for _,p in model:GetChildren() do
    if p:IsA("BasePart") and p~=root then
        local half=p.Size/2
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            lowest=math.min(lowest,(p.CFrame*V(x*half.X,y*half.Y,z*half.Z)).Y)
        end end end
    end
end
h.HipHeight=root.Position.Y-root.Size.Y/2-lowest+.02
local hit=workspace:Raycast(V(12,50,26),V(0,-100,0))
model:PivotTo(CFrame.new(12,(hit and hit.Position.Y or .1)+root.Position.Y-lowest+.02,26))
for _,p in model:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
model.Parent=workspace
game:GetService("Selection"):Set({model})
local focus=model:GetPivot().Position+V(0,.75,.4)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(12,7,-15),focus)
workspace.CurrentCamera.Focus=CFrame.new(focus)
if recording then history:FinishRecording(recording,Enum.FinishRecordingOperation.Commit) end
print("Created",model:GetFullName(),"HipHeight",h.HipHeight)
