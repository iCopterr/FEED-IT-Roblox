-- Editor-only Minotaur pet art recipe, using the sculpted lineup style.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
assert(not workspace:FindFirstChild("Minotaur_V1"),"Minotaur already exists")
local neighbor=assert(workspace:FindFirstChild("Kitsune_V3") or workspace:FindFirstChild("Kitsune_V2"),"Kitsune missing")
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local coal,slate,red,fire,gold=C(35,30,36),C(72,51,51),C(153,48,35),C(255,105,26),C(255,209,96)
local navy,blue,ice,snow,cyan=C(25,43,70),C(73,121,163),C(148,209,231),C(230,249,255),C(99,231,255)
local violet=C(99,73,143)
local function factory(name,size,pos,color)
    local m=Instance.new("Model"); m.Name=name
    local function p(n,s,cf,c,cl,glow)
        local o=Instance.new(cl or "Part")
        o.Name,o.Size,o.CFrame,o.Color=n,s,cf,c
        o.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
        o.TopSurface,o.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.LeftSurface,o.RightSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.FrontSurface,o.BackSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.Anchored,o.CanCollide,o.Massless=true,false,true; o.Parent=m
        return o
    end
    local function d(n,s,cf,c,l,cl,glow)
        local o=p(n,s,cf,c,cl,glow)
        local w=Instance.new("WeldConstraint"); w.Name="DetailWeld"
        w.Part0,w.Part1,w.Parent=l,o,o
        return o
    end
    local t=p("Torso",size,CF(pos),color); t.Transparency=1; t.CanCollide=true; t.Massless=false
    local r=p("HumanoidRootPart",size,t.CFrame,color); r.Transparency=1; r.Massless=false; r.RootPriority=127
    m.PrimaryPart=r
    local function joint(n,a,b,at)
        local j=Instance.new("Motor6D"); j.Name=n; j.Part0=a; j.Part1=b
        j.C0=a.CFrame:ToObjectSpace(CF(at)); j.C1=b.CFrame:ToObjectSpace(CF(at)); j.Parent=a
    end
    joint("RootJoint",r,t,pos)
    local function limb(n,at)
        local l=p(n,V(.25,.25,.25),CF(at),color); l.Transparency=1
        joint("TorsoTo"..n,t,l,at); return l
    end
    local function tri(n,a,b,c,col,l)
        local ab,ac,bc=b-a,c-a,c-b
        if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
        elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
        ab,ac,bc=b-a,c-a,c-b
        if ac:Cross(ab).Magnitude<.00001 then return end
        local right,back=ac:Cross(ab).Unit,bc.Unit
        local up=bc:Cross(right).Unit
        local h=math.abs(ab:Dot(up))
        for i,spec in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
            if spec[4]>.001 then d(n..i,V(.025,h,spec[4]),CFrame.fromMatrix(spec[1],spec[2],up,spec[3]),col,l,"WedgePart") end
        end
    end
    local function segment(n,a,b,wa,ha,wb,hb,col,l)
        local cf=CFrame.lookAt(a,b); local right,up=cf.RightVector,cf.UpVector
        -- Beveled rectangular cross-section softens the large shapes while retaining facets.
        local shape={{-.7,-1},{.7,-1},{1,-.6},{1,.6},{.7,1},{-.7,1},{-1,.6},{-1,-.6}}
        local first,last={},{}
        for i,v in shape do
            first[i]=a+right*v[1]*wa/2+up*v[2]*ha/2
            last[i]=b+right*v[1]*wb/2+up*v[2]*hb/2
        end
        for i=1,8 do
            local j=i%8+1
            local tint=(i==2 or i==7) and col:Lerp(C(255,255,255),.1) or col
            tri(n.."Panel"..i.."A",first[i],first[j],last[i],tint,l)
            tri(n.."Panel"..i.."B",last[i],first[j],last[j],tint,l)
        end
        for i=2,7 do tri(n.."CapA"..i,first[1],first[i],first[i+1],col,l); tri(n.."CapB"..i,last[1],last[i],last[i+1],col,l) end
    end
    local function spike(n,a,b,width,col,l)
        local cf=CFrame.lookAt(a,b); local x,y=cf.RightVector*width/2,cf.UpVector*width/2
        local q={a-x-y,a+x-y,a+x+y,a-x+y}
        for i=1,4 do tri(n..i,q[i],q[i%4+1],b,i%2==0 and col:Lerp(snow,.13) or col,l) end
        tri(n.."BaseA",q[1],q[2],q[3],col,l); tri(n.."BaseB",q[1],q[3],q[4],col,l)
    end
    local function beam(n,a,b,w,col,l,glow) return d(n,V(w,w,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col,l,nil,glow) end
    local function feather(n,a,b,w,col,l)
        local dir=(b-a).Unit; local side=dir:Cross(V(0,1,0))
        if side.Magnitude<.01 then side=V(1,0,0) else side=side.Unit end
        local center=a:Lerp(b,.4)+V(0,.09,0)
        tri(n.."L",a,center-side*w/2,b,col,l)
        tri(n.."R",a,b,center+side*w/2,col:Lerp(snow,.12),l)
        beam(n.."Quill",a,b,.045,col:Lerp(navy,.25),l)
    end
    local h=Instance.new("Humanoid"); h.RigType=Enum.HumanoidRigType.R15
    h.RequiresNeck=false; h.BreakJointsOnDeath=false; h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.Parent=m
    Instance.new("Animator",h)
    return {m=m,t=t,d=d,l=limb,tri=tri,seg=segment,sp=spike,b=beam,f=feather}
end
local hide=C(123,68,45)
local lit=C(160,91,54)
local mane=C(43,29,30)
local hoof=C(31,29,33)
local bone=C(231,211,165)
local metal=C(65,73,81)
local brass=C(196,146,65)
local q=factory("Minotaur_V1",V(3.2,3.4,2.2),V(0,4.45,0),hide)
local m,t=q.m,q.t
q.seg("BroadChest",V(0,5.85,0),V(0,4.3,0),3.85,2.25,3.05,1.95,hide,t)
q.seg("Waist",V(0,4.3,0),V(0,3.25,0),3.05,1.95,2.25,1.65,hide,t)
for _,s in {-1,1} do
 q.seg("Pectoral",V(s*.87,5.42,-1.34),V(s*.82,4.87,-1.43),1.65,.48,1.3,.32,lit,t)
 for j=1,2 do q.seg("Abdominal",V(s*.46,4.5-j*.36,-1.17),V(s*.46,4.27-j*.36,-1.17),.76,.25,.69,.23,hide,t) end
end
local head=q.l("Head",V(0,5.82,-.17))
q.seg("Neck",V(0,5.64,-.03),V(0,6.54,-.36),2.2,1.8,1.9,1.65,mane,head)
q.seg("BullSkull",V(0,7.4,-.14),V(0,6.41,-.54),2.48,1.92,1.96,1.76,hide,head)
q.seg("HeavyMuzzle",V(0,6.53,-.94),V(0,6.33,-1.94),1.66,1.08,1.71,.81,lit,head)
q.seg("NosePad",V(0,6.37,-1.92),V(0,6.36,-2.12),1.4,.65,1.25,.53,mane,head)
q.b("Mouth",V(-.62,6.02,-1.95),V(.62,6.02,-1.95),.04,hoof,head)
for _,s in {-1,1} do
 local side=s<0 and "Left" or "Right"
 q.d("Nostril",V(.29,.18,.055),CF(s*.38,6.4,-2.15),hoof,head)
 q.d(side.."EyeSocket",V(.68,.33,.1),CF(s*.72,6.98,-1.18)*CFrame.Angles(0,s*.2,-s*.15),mane,head)
 q.d(side.."AmberEye",V(.44,.15,.11),CF(s*.72,6.96,-1.25),C(244,160,46),head)
 q.d(side.."Pupil",V(.08,.16,.025),CF(s*.72,6.96,-1.315),hoof,head)
 q.seg("Brow",V(s*.31,7.16,-1.23),V(s*1.11,7.25,-.99),.28,.35,.34,.42,mane,head)
 q.sp("Ear",V(s*1.02,6.99,-.04),V(s*1.91,6.82,-.32),.62,hide,head)
 local points={V(s*.99,7.41,.05),V(s*1.73,7.55,.12),V(s*2.26,7.95,.16),V(s*2.47,8.54,.03),V(s*2.31,9.16,-.17)}
 local widths={.79,.7,.51,.3,.025}
 for i=1,4 do q.seg(side.."Horn"..i,points[i],points[i+1],widths[i],widths[i],widths[i+1],widths[i+1],bone,head) end
 q.seg("HornCuff",points[1],points[1]:Lerp(points[2],.3),.88,.88,.85,.85,brass,head)
 for i=1,4 do q.sp("ManeSide",V(s*(.65+i*.12),6.71-i*.27,.26),V(s*(1.32+i*.11),5.97-i*.36,.25),.85,mane,head) end
 local arm=q.l(side.."Arm",V(s*1.83,5.38,0))
 q.seg("Deltoid",V(s*1.59,5.55,0),V(s*2.43,4.86,-.03),1.45,1.58,1.24,1.34,lit,arm)
 q.seg("UpperArm",V(s*2.18,4.97,-.02),V(s*2.68,4.04,-.18),1.2,1.18,.97,1.04,hide,arm)
 q.seg("Bracer",V(s*2.67,4.18,-.19),V(s*2.88,3.33,-.46),1.28,1.27,1.15,1.15,metal,arm)
 for _,v in {0,.85} do
 local a=V(s*2.67,4.18,-.19):Lerp(V(s*2.88,3.33,-.46),v)
 q.seg("BracerRim",a,a+V(s*.035,-.13,-.04),1.33,1.32,1.33,1.32,brass,arm)
 end
 q.seg("Fist",V(s*2.89,3.38,-.47),V(s*2.94,2.75,-.62),1.1,1.16,1.09,1.09,mane,arm)
 for j=1,3 do q.b("FingerGroove",V(s*2.94+(j-2)*.25,2.83,-1.19),V(s*2.94+(j-2)*.25,3.14,-1.19),.035,hoof,arm) end
 q.sp("Pauldron",V(s*1.94,5.52,.05),V(s*2.64,5.84,.07),1.34,metal,arm)
 q.sp("ShoulderSpike",V(s*2.0,5.97,.06),V(s*2.12,6.61,.08),.32,bone,arm)
 local leg=q.l(side.."Leg",V(s*.85,3.28,0))
 q.seg("Thigh",V(s*.89,3.32,0),V(s*1.16,1.98,-.08),1.19,1.41,.9,.98,hide,leg)
 q.seg("Shin",V(s*1.16,2.03,-.08),V(s*1.23,.71,.04),.89,.95,.64,.69,mane,leg)
 q.seg("KneeGuard",V(s*1.16,2.14,-.6),V(s*1.18,1.75,-.6),.88,.31,.66,.3,metal,leg)
 for _,toe in {-1,1} do q.seg("ClovenHoof",V(s*1.24+toe*.24,.35,.37),V(s*1.24+toe*.24,.29,-.74),.43,.58,.47,.47,hoof,leg) end
end
for i=-2,2 do q.sp("CrownMane",V(i*.36,7.6,.23),V(i*.44,8.1-math.abs(i)*.14,.39),.6,mane,head) end
for i=-1,1 do q.sp("Beard",V(i*.36,6.08,-.8),V(i*.42,5.29+math.abs(i)*.13,-1.0),.62,mane,head) end
-- Faceted gold nose ring.
for i=0,11 do
 local a,b=i*math.pi/6,(i+1)*math.pi/6
 q.b("NoseRing",V(math.sin(a)*.31,6.0+math.cos(a)*.34,-2.2),V(math.sin(b)*.31,6.0+math.cos(b)*.34,-2.2),.095,brass,head)
end
q.seg("Belt",V(0,3.6,0),V(0,3.32,0),2.64,1.86,2.62,1.86,mane,t)
q.d("Buckle",V(.72,.54,.16),CF(0,3.46,-1.02),brass,t)
q.d("BuckleInset",V(.42,.29,.04),CF(0,3.46,-1.12),metal,t)
q.seg("LoinGuard",V(0,3.28,-.87),V(0,2.37,-.83),1.25,.25,.87,.23,metal,t)
local tail=q.l("Tail",V(0,3.43,.84))
q.seg("TailStem",V(0,3.43,.84),V(.27,2.75,1.48),.24,.24,.2,.2,hide,tail)
q.seg("TailEnd",V(.27,2.75,1.48),V(.58,2.39,1.8),.2,.2,.17,.17,hide,tail)
q.sp("TailTuft",V(.58,2.45,1.8),V(.81,1.91,1.98),.49,mane,tail)
local low=math.huge
for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
end end
m.Humanoid.HipHeight=4.45-m.PrimaryPart.Size.Y/2-low+.025
local np=neighbor:GetPivot()
local floor=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
local at=np.Position+np.RightVector*15
m:PivotTo(CF(at.X,floor+4.45-low+.025,at.Z)*np.Rotation)
for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
m:SetAttribute("Purpose","Sculpted Minotaur art prototype; no gameplay integration")
m.Parent=workspace
game:GetService("Selection"):Set({})
local cf=m:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(10,4,-23),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)
print("Created",m.Name,#m:GetDescendants())

