-- Editor-only sculpted Basilisk art recipe.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
assert(not workspace:FindFirstChild("Basilisk_V1"),"Basilisk already exists")
local neighbor=assert(workspace:FindFirstChild("Minotaur_V1"),"Minotaur missing")
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
local green=C(35,89,58)
local leaf=C(65,126,71)
local dark=C(21,54,44)
local belly=C(216,193,120)
local gold=C(211,162,53)
local black=C(21,20,25)
local ivory=C(246,231,179)
local q=factory("Basilisk_V1",V(3.7,2.4,3.8),V(0,1.65,1),green)
local m,t=q.m,q.t
-- Continuous rings keep the bends full and avoid disconnected tube ends.
local function tube(name,points,radii,limb)
 local rings={}
 for i,a in points do
  local tangent=(points[math.min(i+1,#points)]-points[math.max(1,i-1)]).Unit
  local side=tangent:Cross(V(0,1,0))
  if side.Magnitude<.05 then side=V(1,0,0) else side=side.Unit end
  local up=side:Cross(tangent).Unit
  rings[i]={}
  for k=1,10 do local angle=(k-1)*math.pi/5; rings[i][k]=a+(side*math.cos(angle)+up*math.sin(angle))*radii[i] end
 end
 for i=1,#points-1 do for k=1,10 do
  local j=k%10+1
  local color=k<6 and green or dark
  q.tri(name.."A",rings[i][k],rings[i+1][k],rings[i][j],color,limb)
  q.tri(name.."B",rings[i][j],rings[i+1][k],rings[i+1][j],color,limb)
 end end
 for k=1,10 do q.tri(name.."Cap",points[1],rings[1][k],rings[1][k%10+1],green,limb); q.tri(name.."Tip",points[#points],rings[#points][k%10+1],rings[#points][k],green,limb) end
end
local tail=q.l("CoiledTail",V(0,1.15,-1))
local points,radii={},{}
for i=0,24 do
 local f=i/24; local angle=math.rad(-90+f*337); local radius=2.3-f*.35
 points[i+1]=V(math.cos(angle)*radius,.99-f*.38,1.3+math.sin(angle)*radius)
 radii[i+1]=.88*(1-f*.83)
end
points[#points+1]=V(-1.88,.46,-1.63); radii[#radii+1]=.025
tube("Coil",points,radii,tail)
for i=2,23 do
 local p=points[i]; local r=radii[i]
 q.sp("DorsalScale",p+V(0,r*.84,0),p+V(0,r+(.32*(1-i/28)),.29),r*.75,leaf,tail)
 if i%3==0 then q.sp("TailCrest",p+V(0,r,0),p+V(0,r+.49,.23),.25,gold,tail) end
end
local neck=q.l("Neck",V(0,1.35,-1))
local np={V(0,1.12,-1),V(0,2.0,-1.02),V(0,3.04,-.62),V(0,4.02,-.1),V(0,5.05,-.1),V(0,5.91,-.57)}
tube("RaisedNeck",np,{.87,.88,.83,.72,.67,.7},neck)
for i=0,10 do
 local f=i/10; local at=f*(#np-1); local ix=math.min(math.floor(at)+1,#np-1)
 local p=np[ix]:Lerp(np[ix+1],at-(ix-1))
 local radius=.88-f*.2
 q.seg("BellyPlate",p+V(0,-.23,-radius*.81),p+V(0,.23,-radius*.81),radius*1.47,.23,radius*1.39,.2,belly,neck)
end
for _,s in {-1,1} do
 q.tri("HoodWebUpper",V(s*.51,5.78,.15),V(s*1.75,5.24,.28),V(s*.52,3.82,.13),green,neck)
 q.tri("HoodWebLower",V(s*.52,3.82,.13),V(s*1.75,5.24,.28),V(s*1.35,4.05,.25),dark,neck)
 for j=1,6 do
  local y=2.25+j*.44
  local z=y<3.6 and -.57 or -.04
  q.sp("NeckScale",V(s*.67,y,z),V(s*.84,y-.33,z+.28),.43,leaf,neck)
 end
 -- Three raised overlapping hood plates give the cobra silhouette depth.
 for j=1,3 do
  local a=V(s*.47,3.5+j*.55,.0)
  local b=V(s*(1.3+(j==2 and .2 or 0)),3.74+j*.53,.24)
  q.seg("HoodPlate",a,b,.77,.32,.59,.16,leaf,neck)
  q.sp("HoodPoint",b,b+V(s*.3,.35,.05),.37,green,neck)
  q.b("HoodGoldVein",a+V(0,0,-.2),b+V(0,0,-.13),.048,gold,neck)
 end
end
local head=q.l("Head",V(0,5.82,-.58))
q.seg("Skull",V(0,6.12,-.43),V(0,6.09,-1.57),1.66,1.34,1.8,.99,green,head)
q.seg("Snout",V(0,6.08,-1.57),V(0,5.84,-2.63),1.8,.96,1.24,.52,leaf,head)
q.seg("DarkMouth",V(0,5.55,-1.47),V(0,5.43,-2.54),1.46,.24,1.12,.17,black,head)
local jaw=q.l("Jaw",V(0,5.57,-.91))
q.seg("LowerJaw",V(0,5.31,-1.01),V(0,5.14,-2.48),1.32,.33,1.02,.24,belly,jaw)
for _,s in {-1,1} do
 q.d("EyeSocket",V(.1,.43,.73),CF(s*.84,6.16,-1.37)*CFrame.Angles(0,s*.12,0),black,head)
 q.d("GoldenEye",V(.12,.28,.52),CF(s*.902,6.17,-1.38),C(246,171,31),head)
 q.d("SlitPupil",V(.027,.28,.07),CF(s*.968,6.17,-1.44),black,head)
 q.seg("BrowArmor",V(s*.79,6.48,-1.74),V(s*.78,6.57,-.71),.32,.31,.48,.4,dark,head)
 q.d("Nostril",V(.075,.095,.17),CF(s*.62,5.99,-2.39),black,head)
 q.sp("Fang",V(s*.56,5.62,-2.07),V(s*.49,5.12,-2.16),.19,ivory,head)
 for i=1,3 do q.sp("CheekScale",V(s*.76,5.9,-.62+i*.12),V(s*(1.2+i*.04),5.91-i*.16,.25+i*.11),.48,leaf,head) end
 q.sp("CrownHorn",V(s*.59,6.61,-.25),V(s*.96,7.47,.23),.5,gold,head)
end
q.sp("CentralCrest",V(0,6.67,-.66),V(0,7.33,-.05),.56,gold,head)
for i=1,4 do q.sp("NeckSpine",V(0,5.55-i*.68,.52),V(0,5.72-i*.68,1.04),.34,gold,neck) end
-- Small forked tongue, visible inside the open mouth.
q.b("Tongue",V(0,5.35,-1.94),V(0,5.3,-2.96),.065,C(155,49,52),jaw)
for _,s in {-1,1} do q.b("TongueFork",V(0,5.3,-2.96),V(s*.14,5.31,-3.18),.04,C(155,49,52),jaw) end
local low=math.huge
for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
end end
m.Humanoid.HipHeight=1.65-m.PrimaryPart.Size.Y/2-low+.025
local npivot=neighbor:GetPivot()
local floor=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
local pos=npivot.Position+npivot.RightVector*13
m:PivotTo(CF(pos.X,floor+1.65-low+.025,pos.Z)*npivot.Rotation)
for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
m:SetAttribute("Purpose","Sculpted Basilisk art prototype; no gameplay integration")
m.Parent=workspace
game:GetService("Selection"):Set({})
local cf=m:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(10,4,-19),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)
print("Created",m.Name,#m:GetDescendants())

