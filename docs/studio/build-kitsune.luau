-- Editor-only sculpted Kitsune art recipe.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local neighbor=assert(workspace:FindFirstChild("ThunderSerpent_V2"),"Thunder serpent missing")
assert(not workspace:FindFirstChild("Kitsune_V2"),"Kitsune already exists")
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
local pearl=C(242,233,219)
local ivory=C(255,250,235)
local crimson=C(170,34,52)
local vermilion=C(220,58,57)
local ink=C(46,29,46)
local brass=C(198,152,70)
local q=factory("Kitsune_V2",V(2.0,2.1,3.7),V(0,2.75,0),pearl)
local m,t=q.m,q.t
q.seg("Chest",V(0,3.02,-1.43),V(0,2.83,.37),2.06,2.42,1.78,1.94,pearl,t)
q.seg("Waist",V(0,2.83,.37),V(0,2.72,1.89),1.78,1.94,1.49,1.73,pearl,t)
local h=q.l("Head",V(0,3.64,-1.13))
q.seg("Neck",V(0,3.13,-1.28),V(0,4.39,-1.81),1.49,1.64,1.11,1.26,ivory,h)
q.seg("Skull",V(0,4.52,-1.77),V(0,4.4,-2.99),1.49,1.36,1.04,.76,ivory,h)
q.seg("Muzzle",V(0,4.3,-2.91),V(0,4.02,-4.02),.97,.62,.45,.29,pearl,h)
q.seg("Jaw",V(0,3.82,-2.71),V(0,3.69,-3.81),.77,.19,.41,.13,ivory,h)
q.d("Nose",V(.38,.25,.22),CF(0,4.06,-4.05),ink,h)
q.d("ForeheadSeal",V(.32,.47,.045),CF(0,4.99,-2.73)*CFrame.Angles(math.rad(-13),0,math.rad(45)),crimson,h)
for _,s in {-1,1} do
    local n=s<0 and "Left" or "Right"
    q.d(n.."EyeLiner",V(.085,.23,.53),CF(s*.625,4.57,-2.76)*CFrame.Angles(math.rad(-9),0,0),crimson,h)
    q.d(n.."Eye",V(.1,.115,.32),CF(s*.673,4.58,-2.8),C(244,170,74),h)
    q.d(n.."Pupil",V(.02,.11,.065),CF(s*.735,4.58,-2.83),ink,h)
    q.b(n.."SweptEyeMark",V(s*.65,4.57,-2.65),V(s*.81,4.77,-2.17),.07,crimson,h)
    for i=1,2 do q.b(n.."CheekMark"..i,V(s*.69,4.26-i*.14,-2.67),V(s*.8,4.35-i*.13,-2.21),.055,vermilion,h) end
    for i=1,3 do q.sp("CheekFluff",V(s*.7,4.36-i*.18,-1.99),V(s*(1.29+i*.07),3.87-i*.18,-1.09),.47,ivory,h) end
    local e=q.l(n.."Ear",V(s*.53,4.98,-1.93))
    q.sp(n.."EarFur",V(s*.54,4.94,-1.94),V(s*1.03,6.43,-1.58),.69,pearl,e)
    q.tri(n.."InnerEar",V(s*.37,5.12,-2.22),V(s*.95,6.17,-1.78),V(s*.83,5.13,-2.16),crimson,e)
    for i=1,4 do q.sp("NeckRuff",V(s*.64,3.95-i*.18,-1.28),V(s*(1.1+i*.04),3.16-i*.19,-.49),.5,ivory,h) end
    for _,front in {true,false} do
        local z=front and -1.0 or 1.39
        local a,b,c=V(s*.75,2.83,z),V(s*.91,1.48,z+(front and .16 or -.43)),V(s*.88,.36,z-.15)
        local l=q.l(n..(front and "FrontLeg" or "HindLeg"),a)
        q.seg("UpperLeg",a,b,.64,.77,.38,.46,pearl,l)
        q.seg("Shin",b,c,.38,.46,.26,.3,ivory,l)
        q.seg("Paw",c+V(0,-.08,.2),c+V(0,-.08,-.57),.46,.3,.62,.19,ivory,l)
        q.b("RedAnkleRibbon",c+V(-.18,.26,-.17),c+V(.18,.26,-.17),.065,crimson,l)
        for j=1,3 do q.sp("Claw",c+V((j-2)*.18,-.05,-.49),c+V((j-2)*.2,-.18,-.76),.085,brass,l) end
    end
end
-- Nine tails form a symmetrical fan, each with its own Motor6D and tapered tip.
for i=1,9 do
    local angle=math.rad((i-5)*18)
    local x=math.sin(angle)*6.1
    local rise=math.cos(angle)
    local a=V((i-5)*.12,2.84,1.61)
    local b=V(x*.4,3.15+rise*1.35,3.05)
    local c=V(x*.84,3.36+rise*3.32,4.18)
    local d=V(x,3.1+rise*5.7,4.96)
    local split=c:Lerp(d,.61)
    local tail=q.l("Tail"..i,a)
    q.seg("TailBase"..i,a,b,.48,.55,.96,1.05,pearl,tail)
    q.seg("TailPlume"..i,b,c,.96,1.05,1.16,1.25,ivory,tail)
    q.seg("TailTaper"..i,c,split,1.16,1.25,.64,.72,pearl,tail)
    q.seg("RedTailTip"..i,split,d,.64,.72,.035,.05,crimson,tail)
    -- Gold edge at the transition; front-facing so it reads from the fox's face.
    q.b("TailGoldBand"..i,split+V(-.24,0,-.28),split+V(.24,0,-.28),.035,brass,tail)
end
-- A small red collar and golden bell keep the face as a second focal point.
q.b("CollarLeft",V(-.71,3.82,-1.97),V(0,3.45,-2.19),.085,crimson,h)
q.b("CollarRight",V(.71,3.82,-1.97),V(0,3.45,-2.19),.085,crimson,h)
local bell=q.d("Bell",V(.28,.33,.28),CF(0,3.26,-2.21),brass,h)
bell.Shape=Enum.PartType.Ball
q.d("BellSlit",V(.025,.14,.02),CF(0,3.2,-2.36),ink,h)
local low=math.huge
for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
    for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
        low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
    end end end
end end
local root=m.PrimaryPart
m.Humanoid.HipHeight=root.Position.Y-root.Size.Y/2-low+.025
local np=neighbor:GetPivot()
local ground=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
local pos=np.Position+np.RightVector*20
m:PivotTo(CF(pos.X,ground+root.Position.Y-low+.025,pos.Z)*np.Rotation)
for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("Kitsune","Build sculpted nine-tailed Kitsune")
m:SetAttribute("Purpose","Nine-tailed Kitsune art prototype; no gameplay integration")
m.Parent=workspace
game:GetService("Selection"):Set({m})
local cf,size=m:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=45
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(9,5,-18),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m.Name,m:GetPivot().Position)
