-- Editor-only art recipe. Run through Studio MCP; never mapped into runtime.
assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
assert(not workspace:FindFirstChild("IceDragon_V2"), "IceDragon_V2 already exists")
local V, CF = Vector3.new, CFrame.new
local m = Instance.new("Model")
m.Name = "IceDragon_V2"
m:SetAttribute("Purpose", "Reference-inspired angular ice dragon; art trial only")
local frost = Color3.fromRGB(152,207,225)
local shadow = Color3.fromRGB(52,101,142)
local pale = Color3.fromRGB(222,249,255)
local cyan = Color3.fromRGB(84,221,246)
local navy = Color3.fromRGB(16,39,66)
local function part(name,size,cf,color,class)
    local p=Instance.new(class or "Part")
    p.Name,p.Size,p.CFrame,p.Color=name,size,cf,color
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Parent=m
    return p
end
local function weld(p,limb)
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local function detail(name,size,cf,color,limb,class)
    return weld(part(name,size,cf,color,class),limb)
end
local torso=part("Torso",V(2.9,2.7,4.3),CF(0,3.1,0),frost)
torso.Transparency=1 -- Visible faceted body is welded around the sole collider.
torso.CanCollide,torso.Massless=true,false
local root=part("HumanoidRootPart",torso.Size,torso.CFrame,frost)
root.Transparency,root.Massless,root.RootPriority=1,false,127
m.PrimaryPart=root
local function motor(name,a,b,world)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=name,a,b
    j.C0,j.C1=a.CFrame:ToObjectSpace(world),b.CFrame:ToObjectSpace(world)
    j.Parent=a
end
motor("RootJoint",root,torso,root.CFrame)
local function limb(name,pos,anchor)
    local p=part(name,V(.3,.3,.3),CF(pos),frost)
    p.Transparency=1
    motor("TorsoTo"..name,torso,p,CF(anchor))
    return p
end
local function triangle(name,a,b,c,color,parent,studs)
    local ab,ac,bc=b-a,c-a,c-b
    if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
    elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
    ab,ac,bc=b-a,c-a,c-b
    if ac:Cross(ab).Magnitude<.00001 then return end
    local right=ac:Cross(ab).Unit
    local back=bc.Unit
    local up=bc:Cross(right).Unit
    local h=math.abs(ab:Dot(up))
    for i,spec in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
        if spec[4]>.001 then
            local p=detail(name..i,V(.035,h,spec[4]),CFrame.fromMatrix(spec[1],spec[2],up,spec[3]),color,parent,"WedgePart")
            if studs then
                for _,face in {Enum.NormalId.Left,Enum.NormalId.Right} do
                    local t=Instance.new("Texture")
                    t.Name="SubtleStuds"
                    t.Texture="rbxassetid://6927295847"
                    t.Face,t.StudsPerTileU,t.StudsPerTileV=face,1.8,1.8
                    t.Transparency=.83
                    t.Color3=shadow
                    t.Parent=p
                end
            end
        end
    end
end
-- Tapered four-sided segments give deliberate facets, rather than stacked cubes.
local function segment(name,a,b,wa,ha,wb,hb,color,parent,studs)
    local basis=CFrame.lookAt(a,b)
    local right,up=basis.RightVector,basis.UpVector
    local corners={V(-1,-1,0),V(1,-1,0),V(1,1,0),V(-1,1,0)}
    local first,last={},{}
    for i,c in corners do
        first[i]=a+right*c.X*wa/2+up*c.Y*ha/2
        last[i]=b+right*c.X*wb/2+up*c.Y*hb/2
    end
    for i=1,4 do
        local j=i%4+1
        local tint=i==1 and shadow or color
        triangle(name.."Side"..i.."a",first[i],first[j],last[i],tint,parent,studs)
        triangle(name.."Side"..i.."b",last[i],first[j],last[j],tint,parent,studs)
    end
    triangle(name.."CapA",first[1],first[2],first[3],color,parent)
    triangle(name.."CapB",first[1],first[3],first[4],color,parent)
    triangle(name.."CapC",last[1],last[2],last[3],color,parent)
    triangle(name.."CapD",last[1],last[3],last[4],color,parent)
end
local function spike(name,a,b,width,color,parent)
    segment(name,a,b,width,width,.035,.035,color,parent)
end
segment("Chest",V(0,3.4,-1.65),V(0,3.15,.45),2.8,3.1,3.1,2.8,frost,torso,true)
segment("Haunch",V(0,3.15,.45),V(0,2.9,2.25),3.1,2.8,1.55,1.65,frost,torso,true)
local head=limb("Head",V(0,7,-3.5),V(0,4.3,-1.7))
local neck={V(0,3.95,-1.6),V(0,5.15,-2.15),V(0,6.6,-2.35),V(0,7.45,-3.0)}
for i=1,3 do segment("Neck"..i,neck[i],neck[i+1],1.65-i*.16,1.7-i*.12,1.49-i*.16,1.58-i*.12,frost,head,true) end
segment("Skull",V(0,7.5,-2.8),V(0,7.4,-4.45),1.5,1.45,1.2,.9,frost,head,true)
segment("Snout",V(0,7.4,-4.4),V(0,7.1,-5.45),1.2,.78,.67,.4,pale,head)
segment("Jaw",V(0,6.9,-3.65),V(0,6.56,-5.26),1.0,.28,.65,.2,shadow,head)
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    local eye=detail(side.."Eye",V(.09,.22,.48),CF(s*.7,7.62,-4.15),cyan,head)
    eye.Material=Enum.Material.Neon
    detail(side.."Pupil",V(.025,.21,.055),CF(s*.755,7.62,-4.23),navy,head)
    segment(side.."Brow",V(s*.66,7.88,-3.84),V(s*.57,7.75,-4.63),.25,.22,.12,.12,shadow,head)
    spike(side.."CrownHorn",V(s*.59,7.97,-2.98),V(s*1.38,9.15,-1.65),.55,pale,head)
    spike(side.."CheekHorn",V(s*.7,7.15,-3.1),V(s*1.55,7.65,-1.86),.4,cyan,head)
    for i=1,4 do spike(side.."Tooth"..i,V(s*(.45-i*.035),7.01,-4.03-i*.27),V(s*(.45-i*.035),6.72,-4.08-i*.27),.13,pale,head) end
    for _,front in {true,false} do
        local z=front and -1.23 or 1.46
        local name=side..(front and "FrontLeg" or "HindLeg")
        local a=V(s*1.16,3.05,z)
        local b=V(s*1.65,1.75,z+(front and .25 or -.55))
        local c=V(s*1.58,.5,z-.17)
        local leg=limb(name,a,a)
        segment(name.."Upper",a,b,.88,.98,.59,.63,frost,leg)
        segment(name.."Lower",b,c,.58,.64,.38,.45,shadow,leg)
        segment(name.."Foot",c+V(0,-.2,.24),c+V(0,-.2,-.79),.68,.43,.88,.26,frost,leg)
        for i=1,3 do spike(name.."Claw"..i,V(c.X+(i-2)*.28,.25,c.Z-.7),V(c.X+(i-2)*.31,.12,c.Z-1.2),.19,pale,leg) end
    end
    local a=V(s*1.3,4.05,-.7)
    local b=V(s*3.35,6.05,.2)
    local tip=V(s*8.7,7.25,2.2)
    local ends={tip,V(s*7.8,4.55,4.0),V(s*5.3,3.3,4.4),V(s*2.75,3.05,3.25),V(s*1.3,3.5,1.6)}
    local wing=limb(side.."Wing",a,a)
    segment(side.."WingArm",a,b,.58,.58,.37,.37,shadow,wing)
    segment(side.."LeadingEdge",b,tip,.36,.38,.075,.1,pale,wing)
    for i=1,4 do
        local notch=(ends[i]+ends[i+1])/2+(b-(ends[i]+ends[i+1])/2)*.23
        triangle(side.."Sail"..i.."A",b,ends[i],notch,i%2==0 and frost or pale,wing,true)
        triangle(side.."Sail"..i.."B",b,notch,ends[i+1],i%2==0 and frost or pale,wing,true)
        if i>1 then segment(side.."WingFinger"..i,b,ends[i],.19,.2,.065,.07,shadow,wing) end
    end
    triangle(side.."WingRoot",a,b,ends[5],frost,wing,true)
    spike(side.."WingThumb",b,b+V(s*.1,1.03,-.23),.32,cyan,wing)
end
local tail=limb("Tail",V(0,2.9,2.1),V(0,2.9,2.1))
local points={V(0,2.9,2.1),V(.15,2.45,3.8),V(.5,2.0,5.45),V(1.3,1.9,6.9),V(2.45,2.35,8.05),V(3.7,3.0,8.75)}
for i=1,5 do segment("Tail"..i,points[i],points[i+1],1.35-(i-1)*.24,1.25-(i-1)*.21,1.35-i*.24,1.25-i*.21,frost,tail,true) end
spike("TailCrystal",points[6],V(4.65,3.8,9.25),.7,cyan,tail)
for i=1,5 do
    local a=V(0,4.8-(i-1)*.22,-1.3+(i-1)*.87)
    spike("BackSpine"..i,a,a+V(0,1.0-(i-1)*.11,.55),.53,i%2==0 and pale or cyan,torso)
end
for i=1,3 do
    local a=neck[i+1]+V(0,.1,.64)
    spike("NeckFrill"..i,a,a+V(0,.8,1.0),.47,pale,head)
end
local h=Instance.new("Humanoid")
h.RigType,h.RequiresNeck=Enum.HumanoidRigType.R15,false
h.BreakJointsOnDeath=false
h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
h.Parent=m
Instance.new("Animator",h)
local lowest=math.huge
for _,p in m:GetChildren() do
    if p:IsA("BasePart") and p.Transparency<1 then
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            lowest=math.min(lowest,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
        end end end
    end
end
h.HipHeight=root.Position.Y-root.Size.Y/2-lowest+.03
local hit=workspace:Raycast(V(13,60,49),V(0,-120,0))
m:PivotTo(CF(13,(hit and hit.Position.Y or .1)+root.Position.Y-lowest+.03,49))
for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("IceDragonV2","Create reference-style ice dragon")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local focus=m:GetPivot().Position+V(0,2,1)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(17,10,-23),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m:GetFullName(),"children",#m:GetChildren())
