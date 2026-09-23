-- Editor-only concept study. No runtime generation or animation scripts.
assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
assert(not workspace:FindFirstChild("IvoryWraith_Concept"), "Model already exists")
local V,CF=Vector3.new,CFrame.new
local model=Instance.new("Model")
model.Name="IvoryWraith_Concept"
model:SetAttribute("Purpose","Ivory armored spirit with emerging shadow beast; standalone art study")
local ivory=Color3.fromRGB(225,220,197)
local highlight=Color3.fromRGB(248,244,221)
local gold=Color3.fromRGB(153,118,58)
local void=Color3.fromRGB(24,20,36)
local purple=Color3.fromRGB(46,36,62)
local function part(name,size,cf,color,class)
    local p=Instance.new(class or "Part")
    p.Name,p.Size,p.CFrame,p.Color=name,size,cf,color
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Parent=model
    return p
end
local function weld(p,limb)
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local function detail(n,s,c,col,limb,class) return weld(part(n,s,c,col,class),limb) end
local function beam(n,a,b,width,col,limb,depth)
    return detail(n,V(width,depth or width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col,limb)
end
local function spike(n,a,b,width,col,limb)
    -- Crossed tapered wedges give a sharp diamond silhouette with only two parts.
    local axis=(b-a).Unit
    local basis=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0)
    local length=(b-a).Magnitude
    detail(n.."A",V(width*.3,length,width),basis,col,limb,"WedgePart")
    detail(n.."B",V(width*.3,length,width),basis*CFrame.Angles(0,math.pi,0),col,limb,"WedgePart")
end
local function orb(n,pos,size,col,limb)
    local p=detail(n,size,CF(pos),col,limb)
    p.Shape=Enum.PartType.Ball
    return p
end
local torso=part("Torso",V(2.25,2.65,4.1),CF(0,5.9,.4),void)
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,void)
root.Transparency,root.RootPriority,root.Massless=1,127,false
model.PrimaryPart=root
local function joint(name,p0,p1,at)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=name,p0,p1
    j.C0,j.C1=p0.CFrame:ToObjectSpace(CF(at)),p1.CFrame:ToObjectSpace(CF(at))
    j.Parent=p0
end
joint("RootJoint",root,torso,root.Position)
local function limb(n,at,anchor)
    local p=part(n,V(.25,.25,.25),CF(at),void)
    p.Transparency=1
    joint("TorsoTo"..n,torso,p,anchor)
    return p
end
-- Oval armor frames leave dark recessed apertures, the reference's central motif.
local function frame(n,center,ry,rz,s,limb)
    local count=10
    for i=0,count-1 do
        local a,b=2*math.pi*i/count,2*math.pi*(i+1)/count
        local p=center+V(0,math.cos(a)*ry,math.sin(a)*rz)
        local q=center+V(0,math.cos(b)*ry,math.sin(b)*rz)
        beam(n..i,p,q,.23,ivory,limb,.29)
        beam(n.."Gold"..i,p+V(s*.135,0,0),q+V(s*.135,0,0),.035,gold,limb)
    end
end
orb("ShadowRibcage",V(0,6,.55),V(2.7,3.1,4.7),void,torso)
for _,s in {-1,1} do
    frame("ShoulderAperture"..s,V(s*1.34,6.45,-.72),1.48,.76,s,torso)
    frame("FlankAperture"..s,V(s*1.32,6.17,1.12),.95,.86,s,torso)
    frame("HipAperture"..s,V(s*.98,5.76,2.38),.75,.55,s,torso)
    spike("ShoulderBlade"..s,V(s*1.25,7.28,-1.55),V(s*1.53,4.72,-1.35),.72,highlight,torso)
    beam("Ridge"..s,V(s*.65,7.3,-1.25),V(s*.65,7.1,2.3),.24,ivory,torso)
end
local head=limb("Head",V(0,10.2,-3.8),V(0,7.15,-1.15))
local neck={V(0,6.7,-1.25),V(0,8.35,-1.35),V(0,10.1,-2),V(0,10.9,-3.25),V(0,10.25,-4.35)}
for i=1,#neck-1 do
    beam("DarkNeck"..i,neck[i],neck[i+1],1.0-i*.1,void,head,.9)
    for _,s in {-1,1} do
        beam("NeckArmor"..s..i,neck[i]+V(s*.5,.2,.15),neck[i+1]+V(s*.42,.2,.15),.3,ivory,head,.38)
        beam("NeckGold"..s..i,neck[i]+V(s*.66,.2,.15),neck[i+1]+V(s*.56,.2,.15),.036,gold,head)
    end
end
for _,s in {-1,1} do
    frame("NeckWindow"..s,V(s*.49,8.9,-1.54),1.0,.43,s,head)
    spike("FacePlate"..s,V(s*.4,10.8,-3.8),V(s*.16,8.77,-5.15),.66,highlight,head)
    spike("Mandible"..s,V(s*.33,9.9,-4.12),V(s*.25,8.54,-4.82),.26,ivory,head)
    local eye=orb("Eye"..s,V(s*.46,10.13,-4.42),V(.12,.22,.32),Color3.fromRGB(211,177,104),head)
    eye.Material=Enum.Material.Neon
    local horn=V(s*.46,10.72,-3.17)
    local bend=V(s*1.08,12.13,-2.87)
    beam("AntlerBase"..s,horn,bend,.28,ivory,head)
    spike("Crown"..s,bend,V(s*1.62,14.0,-3.05),.36,highlight,head)
    spike("AntlerBranch"..s,V(s*.85,11.73,-2.97),V(s*2.0,12.2,-2.62),.25,ivory,head)
    spike("BrowHorn"..s,V(s*.4,10.35,-4.1),V(s*1.38,11.83,-5.14),.3,ivory,head)
end
for i=1,5 do
    local a=V(0,10.7-(i-1)*.75,-2.45+(i-1)*.89)
    spike("SweptSpine"..i,a,a+V(0,.5,1.2),.45,ivory,i<=3 and head or torso)
end
-- Four elongated digitigrade legs with small gold cuffs and split pointed claws.
for _,s in {-1,1} do for _,front in {true,false} do
    local n=(s==-1 and "Left" or "Right")..(front and "FrontLeg" or "HindLeg")
    local a=V(s*1.04,5.8,front and -1.12 or 2.13)
    local b=V(s*1.5,3.12,front and -2.0 or 3.4)
    local c=V(s*1.82,.61,front and -3.1 or 2.72)
    local l=limb(n,a,a)
    beam(n.."Core",a,b,.34,void,l)
    spike(n.."ThighArmor",a,b,.8,ivory,l)
    beam(n.."ShinCore",b,c,.25,void,l)
    spike(n.."ShinArmor",b,c,.51,highlight,l)
    orb(n.."Knee",b,V(.52,.55,.55),ivory,l)
    beam(n.."Cuff",b+V(-.31,-.17,0),b+V(.31,-.17,0),.1,gold,l)
    for j=-1,1,2 do spike(n.."Claw"..j,c+V(j*.18,0,0),c+V(j*.33,-.48,-.77),.25,ivory,l) end
end end
local tail=limb("Tail",V(0,6.25,2.55),V(0,6.25,2.3))
local tailPoints={V(0,6.25,2.4),V(.3,5.65,3.8),V(.7,3.65,4.55),V(1.0,1.55,5.45),V(2.3,.5,6.5)}
for i=1,4 do
    beam("TailShadow"..i,tailPoints[i],tailPoints[i+1],.75-i*.12,purple,tail)
    spike("TailArmor"..i,tailPoints[i]+V(0,.12,0),tailPoints[i+1],.78-i*.1,ivory,tail)
    spike("TailHook"..i,tailPoints[i],tailPoints[i]+V(.7,.65,.6),.26,ivory,tail)
end
-- Chains are fixed decorative links; no simulated hanging physics or animation.
local function pendant(n,points,parent)
    for i=1,#points-1 do beam(n.."Chain"..i,points[i],points[i+1],.037,gold,parent) end
    local endp=points[#points]
    orb(n.."Bead",endp,V(.16,.16,.16),gold,parent)
    spike(n.."Charm",endp-V(0,.08,0),endp-V(0,.64,0),.19,gold,parent)
end
pendant("Bridle",{V(-1.17,11.38,-4.97),V(-1.27,8.72,-5.36),V(-.52,7.55,-5.53),V(.2,7.2,-5.48)},head)
pendant("BridleReturn",{V(1.17,11.38,-4.97),V(1.14,8.8,-5.32),V(.2,7.2,-5.48)},head)
pendant("FlankCharm",{V(1.3,6.25,1.12),V(1.6,4.85,1.1),V(1.53,4.25,1.0)},torso)
pendant("TailCharm",{V(.73,3.7,4.55),V(.73,2.7,4.55)},tail)
local shadow=limb("ShadowBeast",V(0,.55,-.4),V(0,4.8,.6))
orb("ShadowPool",V(0,.2,.3),V(4.1,.28,7.4),void,shadow)
orb("ShadowSkull",V(0,.82,-3.3),V(1.9,1.04,2.5),purple,shadow)
spike("ShadowMuzzle",V(0,.9,-3.5),V(0,.3,-5.26),1.45,void,shadow)
detail("ShadowMouth",V(1.2,.31,.09),CF(0,.57,-4.26)*CFrame.Angles(math.rad(-15),0,0),void,shadow)
for _,s in {-1,1} do
    local e=detail("ShadowEye"..s,V(.24,.12,.56),CF(s*.56,1.22,-3.62)*CFrame.Angles(0,0,s*.3),highlight,shadow)
    e.Material=Enum.Material.Neon
    spike("ShadowHorn"..s,V(s*.69,1.04,-2.57),V(s*1.68,1.23,-.92),.42,purple,shadow)
    local a,b,c=V(s*.92,.51,-1.2),V(s*2.7,.36,-2.4),V(s*3.65,.21,-4.04)
    beam("ShadowArm"..s,a,b,.38,purple,shadow)
    spike("ShadowForearm"..s,b,c,.44,purple,shadow)
    for i=1,3 do
        local p=c+V(s*(i-2)*.22,0,0)
        spike("ShadowFinger"..s..i,p,p+V(s*(i-2)*.6,-.05,-1.23+i*.16),.19,void,shadow)
    end
    for i=1,7 do
        spike("ShadowTooth"..s..i,V(s*(.08+i*.075),.68,-4.0-i*.04),V(s*(.08+i*.075),.38,-4.07-i*.04),.1,highlight,shadow)
    end
    for i=1,5 do
        local a=V(s*.62,.32,i*.76-.25)
        local b=a+V(s*(1.3+i*.14),.11,.8)
        spike("SmokeTongue"..s..i,a,b,.46,purple,shadow)
        spike("SmokeTip"..s..i,b,b+V(s*.66,.09,-.55),.2,void,shadow)
    end
    -- Ragged strips connect the dark inner body to the shadow creature below.
    for i=1,3 do
        local a=V(s*.65,5.05,1.0+i*.45)
        local b=V(s*(1.0+i*.14),2.55,1.8+i*.47)
        spike("TrailingShroud"..s..i,a,b,.82,purple,shadow)
        spike("TrailingShroudTip"..s..i,b,V(s*.8,.3,2.6+i*.37),.6,void,shadow)
    end
end
local h=Instance.new("Humanoid")
h.RigType=Enum.HumanoidRigType.R15
h.RequiresNeck,h.BreakJointsOnDeath=false,false
h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
h.Parent=model
Instance.new("Animator",h)
local lowest=math.huge
for _,p in model:GetChildren() do if p:IsA("BasePart") and p.Transparency<1 then
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        lowest=math.min(lowest,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
    end end end
end end
h.HipHeight=root.Position.Y-root.Size.Y/2-lowest+.035
local hit=workspace:Raycast(V(13,60,78),V(0,-120,0))
model:PivotTo(CF(13,(hit and hit.Position.Y or .1)+root.Position.Y-lowest+.035,78))
for _,p in model:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("IvoryWraith","Create ivory and shadow concept creature")
model.Parent=workspace
game:GetService("Selection"):Set({model})
local focus=model:GetPivot().Position+V(0,1,-.7)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(18,9,-24),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",model:GetFullName(),"children",#model:GetChildren())
