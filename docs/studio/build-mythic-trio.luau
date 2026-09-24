-- Editor-only sculpted Manticore, Chimera and Cerberus art recipes.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
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
local ochre=C(170,108,48)
local cream=C(232,195,125)
local rust=C(113,44,31)
local ink=C(30,27,34)
local armor=C(56,49,61)
local bone=C(227,213,173)
local flame=C(245,101,32)
local function beast(name,col)
 local q=factory(name,V(2.8,2.4,4.4),V(0,2.6,.3),col)
 q.seg("Chest",V(0,2.83,-1.7),V(0,2.67,.35),2.9,2.7,2.55,2.3,col,q.t)
 q.seg("Flank",V(0,2.67,.35),V(0,2.65,2.33),2.55,2.3,2.25,2.08,col,q.t)
 for _,s in {-1,1} do for _,front in {true,false} do
  local z=front and -1.22 or 1.79
  local l=q.l((s<0 and "Left" or "Right")..(front and "FrontLeg" or "HindLeg"),V(s*.96,2.65,z))
  q.seg("Thigh",V(s*1.0,2.7,z),V(s*1.16,1.39,z+.23),.98,1.26,.65,.79,col,l)
  q.seg("Shin",V(s*1.16,1.39,z+.23),V(s*1.18,.4,z-.13),.65,.79,.5,.5,col,l)
  q.seg("Paw",V(s*1.18,.36,z+.1),V(s*1.18,.3,z-.87),.83,.56,.98,.42,col,l)
  for j=1,3 do q.sp("Claw",V(s*1.18+(j-2)*.27,.3,z-.77),V(s*1.18+(j-2)*.28,.15,z-1.08),.15,bone,l) end
 end end
 return q
end
local function face(q,n,origin,col,kind,scale)
 local l=q.l(n,origin)
 local function v(x,y,z) return origin+V(x,y,z)*scale end
 local function seg(n,a,b,w,h,ww,hh,c) q.seg(n,a,b,w*scale,h*scale,ww*scale,hh*scale,c,l) end
 seg(n.."Neck",v(0,-.72,.52),v(0,0,.15),1.6,1.7,1.53,1.7,col)
 seg(n.."Skull",v(0,.47,.38),v(0,.35,-.86),1.85,1.62,1.49,1.18,col)
 seg(n.."Snout",v(0,.1,-.77),v(0,-.03,-1.67),1.32,.8,.94,.51,kind=="Lion" and cream or col)
 seg(n.."Mouth",v(0,-.32,-.88),v(0,-.36,-1.61),1.16,.25,.84,.16,ink)
 seg(n.."Jaw",v(0,-.58,-.59),v(0,-.56,-1.51),1.06,.26,.79,.22,col)
 q.d(n.."Nose",V(.62,.31,.16)*scale,CF(v(0,.03,-1.73)),ink,l)
 for _,s in {-1,1} do
  q.d(n.."Socket",V(.11,.35,.63)*scale,CF(v(s*.76,.4,-.69)),ink,l)
  q.d(n.."Eye",V(.12,.19,.41)*scale,CF(v(s*.82,.41,-.73)),flame,l)
  q.d(n.."Pupil",V(.025,.2,.065)*scale,CF(v(s*.888,.41,-.78)),ink,l)
  seg(n.."Brow",v(s*.76,.67,-.97),v(s*.82,.73,-.25),.25,.25,.34,.34,col)
  q.sp(n.."Fang",v(s*.43,-.2,-1.26),v(s*.37,-.67,-1.35),.17*scale,bone,l)
  q.sp(n.."Ear",v(s*.7,.89,.17),v(s*1.01,kind=="Wolf" and 1.71 or 1.27,.24),.55*scale,col,l)
 end
 if kind=="Lion" then
  for i=0,13 do
   local a=i*math.pi/7
   local x,y=math.cos(a),math.sin(a)
   q.sp(n.."Mane",v(x*.98,y*.98,.36),v(x*1.66,y*1.66-.13,.79),.82*scale,rust,l)
  end
 elseif kind=="Goat" then
  for _,s in {-1,1} do
   seg("GoatHorn",v(s*.55,.91,.03),v(s*.77,1.65,.32),.43,.43,.28,.28,bone)
   seg("GoatHornCurl",v(s*.77,1.65,.32),v(s*.72,1.8,.91),.28,.28,.06,.06,bone)
  end
  q.sp("GoatBeard",v(0,-.54,-.58),v(0,-1.17,-.39),.47*scale,cream,l)
 else
  for _,s in {-1,1} do for i=1,3 do q.sp(n.."Ruff",v(s*.7,-.14-i*.18,.24),v(s*(1.22+i*.05),-.39-i*.28,.68),.55*scale,col,l) end end
 end
 return l,v
end
local function wings(q,spread)
 for _,s in {-1,1} do
  local a=V(s*.99,3.35,.14); local elbow=V(s*2.55,5.54,.62); local tip=V(s*spread,6.31,1.13)
  local l=q.l((s<0 and "Left" or "Right").."Wing",a)
  q.seg("WingArm",a,elbow,.34,.4,.25,.31,rust,l)
  q.seg("WingLeadingEdge",elbow,tip,.25,.31,.055,.08,rust,l)
  local ends={tip,V(s*(spread-.5),4.76,2.18),V(s*3.19,3.93,2.75),V(s*1.34,3.09,2.46)}
  for i=1,3 do
   q.tri("WingMembrane",elbow,ends[i],ends[i+1],i%2==0 and C(154,63,42) or C(129,46,39),l)
   q.b("WingFinger",elbow,ends[i+1],.09,rust,l)
  end
  q.tri("WingRootWeb",a,elbow,ends[4],rust,l)
  q.sp("WingClaw",elbow,elbow+V(s*.2,.52,-.17),.2,bone,l)
 end
end
local function tail(q,scorpion)
 local l=q.l("Tail",V(0,2.66,2.15))
 local pts={V(0,2.66,2.15),V(.35,2.77,3.19),V(.84,3.32,4.14),V(1.1,4.24,4.55),V(.97,5.1,4.26),V(.45,5.43,3.59)}
 for i=1,#pts-1 do
  local w=scorpion and (.58-i*.05) or (.39-i*.035)
  q.seg("TailSegment",pts[i],pts[i+1],w,w,w*.86,w*.86,scorpion and rust or ink,l)
 end
 q.sp(scorpion and "ScorpionStinger" or "TailBlade",pts[#pts],V(.21,4.62,3.03),scorpion and .62 or .37,scorpion and ink or flame,l)
end
local names={"Manticore_V1","Chimera_V1","Cerberus_V1"}
for _,n in names do assert(not workspace:FindFirstChild(n),n.." already exists") end
local neighbor=assert(workspace:FindFirstChild("Basilisk_V1"),"Basilisk missing")
local models={}
local q=beast(names[1],ochre)
face(q,"Head",V(0,3.85,-2.1),ochre,"Lion",1)
wings(q,5.2); tail(q,true); table.insert(models,q.m)
q=beast(names[2],C(129,86,49))
face(q,"LionHead",V(0,3.67,-2.03),ochre,"Lion",.9)
local dragon,dv=face(q,"DragonHead",V(-1.48,4.58,-.83),C(128,47,38),"Dragon",.85)
for _,s in {-1,1} do q.sp("DragonHorn",dv(s*.57,.92,.2),dv(s*.78,1.66,.86),.31,bone,dragon) end
face(q,"GoatHead",V(1.44,4.56,-.68),C(188,183,164),"Goat",.83)
wings(q,4.65); tail(q,false); table.insert(models,q.m)
q=beast(names[3],ink)
face(q,"CenterHead",V(0,4.15,-2.07),armor,"Wolf",.98)
face(q,"LeftHead",V(-1.72,3.52,-1.69),ink,"Wolf",.87)
face(q,"RightHead",V(1.72,3.52,-1.69),ink,"Wolf",.87)
for _,s in {-1,1} do
 for i=1,5 do
  q.sp("BackArmor",V(s*.82,3.61,.02+i*.37),V(s*1.31,4.09,.49+i*.37),.7,armor,q.t)
  q.b("EmberFlank",V(s*1.26,2.75,.24+i*.28),V(s*1.29,2.99,.42+i*.28),.065,flame,q.t)
 end
 q.seg("IronCollar",V(s*1.44,3.11,-1.09),V(s*1.44,3.3,-1.1),1.43,1.49,1.43,1.49,coal,q.t)
 for i=1,3 do q.sp("CollarSpike",V(s*(.98+i*.21),3.7,-1.0),V(s*(.99+i*.3),4.14,-.88),.18,bone,q.t) end
end
tail(q,false); table.insert(models,q.m)
local np=neighbor:GetPivot()
local floor=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
for i,m in models do
 local low=math.huge
 for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
 end end
 m.Humanoid.HipHeight=2.6-m.PrimaryPart.Size.Y/2-low+.025
 local at=np.Position+np.RightVector*(i*15)
 m:PivotTo(CF(at.X,floor+2.6-low+.025,at.Z)*np.Rotation)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
 m:SetAttribute("Purpose","Sculpted pet art prototype; no gameplay integration")
 m.Parent=workspace
 print("Created",m.Name,#m:GetDescendants())
end
game:GetService("Selection"):Set({})
local cf=models[1]:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(11,6,-21),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)

-- Final visual pass: expose the stinger and add restrained ember face marks.
local mant=workspace.Manticore_V1
local mt=mant.Tail
local delta=mant:GetPivot().RightVector*1.65
for _,p in mant:GetDescendants() do
 if p:IsA("BasePart") and (p.Name=="TailSegment" or p.Name:match("^TailSegment") or p.Name:match("^ScorpionStinger")) then p.CFrame+=delta end
end
-- Connect the shifted armored tail to its rump with a welded base.
local base=Instance.new("Part")
base.Name="TailBaseBridge"; base.Size=V(1.85,.47,.48)
base.CFrame=mant:GetPivot()*CF(.8,.06,1.9)
base.Color=rust; base.Material=Enum.Material.SmoothPlastic
base.CanCollide=false; base.Massless=true; base.Parent=mant
local weld=Instance.new("WeldConstraint",base); weld.Part0=mt; weld.Part1=base
local cer=workspace.Cerberus_V1
for _,n in {"CenterHead","LeftHead","RightHead"} do
 local h=cer[n]
 for _,s in {-1,1} do
  local mark=Instance.new("Part")
  mark.Name="EmberCheek"; mark.Size=V(.07,.085,.54)
  mark.CFrame=h.CFrame*CF(s*.73,.12,-.35)*CFrame.Angles(math.rad(-22),0,0)
  mark.Color=flame; mark.Material=Enum.Material.Neon
  mark.CanCollide=false; mark.Massless=true; mark.Parent=cer
  local w=Instance.new("WeldConstraint",mark); w.Part0=h; w.Part1=mark
 end
end

