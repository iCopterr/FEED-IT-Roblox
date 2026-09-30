-- Editor-only reference Ember Drake; consolidate before delivery.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
assert(not workspace:FindFirstChild("EmberDrake_Reference"),"Already built")
assert(not game:GetService("ServerStorage"):FindFirstChild("EmberDrake_Reference"),"Unfinished build exists; inspect before retry")
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local coal,slate,red,fire,gold=C(35,30,36),C(72,51,51),C(153,48,35),C(255,105,26),C(255,209,96)
local navy,blue,ice,snow,cyan=C(25,43,70),C(73,121,163),C(148,209,231),C(230,249,255),C(99,231,255)
local violet=C(99,73,143)
local function factory(name,size,pos,color)
    local m=Instance.new("Model"); m.Name=name; m.Parent=game:GetService("ServerStorage")
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
    local function solid(n,vertices,faces,col,l)
        local lower,upper=vertices[1],vertices[1]
        local center=V(0,0,0)
        for _,v in vertices do lower=lower:Min(v); upper=upper:Max(v); center+=v end
        center/=#vertices
        local base=p(n,(upper-lower):Max(V(.02,.02,.02)),CF((lower+upper)/2),col)
        local cutters={}; local planes={}; local big=(upper-lower).Magnitude*5+10
        for _,f in faces do
            local a,b,c=vertices[f[1]],vertices[f[2]],vertices[f[3]]
            local normal=(b-a):Cross(c-a)
            if normal.Magnitude<.00001 then continue end
            normal=normal.Unit; if normal:Dot(a-center)<0 then normal=-normal end
            local distance=normal:Dot(a)
            local key=string.format("%.4f:%.4f:%.4f:%.4f",normal.X,normal.Y,normal.Z,distance)
            if planes[key] then continue end; planes[key]=true
            local at=a+normal*(big/2+.0001)
            table.insert(cutters,p("Cut",V(big,big,big),CFrame.lookAt(at,at+normal),col))
        end
        local o=base:SubtractAsync(cutters,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Precise)
        base:Destroy(); for _,c in cutters do c:Destroy() end
        o.Name=n; o.Color=col; o.UsePartColor=true; o.Anchored=true; o.CanCollide=false; o.Massless=true; o.Parent=m
        local w=Instance.new("WeldConstraint",o); w.Part0=l; w.Part1=o
        return o
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
        local vertices={}; for _,v in first do table.insert(vertices,v) end; for _,v in last do table.insert(vertices,v) end
        local faces={}
        for i=1,8 do
            local j=i%8+1
            table.insert(faces,{i,j,i+8}); table.insert(faces,{i+8,j,j+8})
        end
        table.insert(faces,{1,2,3}); table.insert(faces,{9,10,11}); solid(n,vertices,faces,col,l)
    end
    local function spike(n,a,b,width,col,l)
        local cf=CFrame.lookAt(a,b); local x,y=cf.RightVector*width/2,cf.UpVector*width/2
        local q={a-x-y,a+x-y,a+x+y,a-x+y}
        table.insert(q,b)
        solid(n,q,{{1,2,5},{2,3,5},{3,4,5},{4,1,5},{1,2,3}},col,l)
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
    return {m=m,t=t,d=d,l=limb,tri=tri,seg=segment,sp=spike,b=beam,f=feather,solid=solid}
end
local rust=C(167,68,39)
local warm=C(191,80,43)
local shade=C(132,49,30)
local amber=C(240,165,65)
local cream=C(255,213,139)
local ink=C(22,24,27)
local q=factory("EmberDrake_Reference",V(2.3,2.3,3.3),V(0,2.55,.2),rust)
local m,t=q.m,q.t
-- Short rings rather than long box-like sections create rounded faceted masses.
local function loft(name,centers,widths,heights,col,limb)
 local rings={}
 for i,p in centers do
  local tangent=(centers[math.min(i+1,#centers)]-centers[math.max(i-1,1)]).Unit
  local right=tangent:Cross(V(0,1,0)); if right.Magnitude<.01 then right=V(1,0,0) else right=right.Unit end
  local up=right:Cross(tangent).Unit
  rings[i]={}
  for j=1,8 do local a=(j-.5)*math.pi/4; rings[i][j]=p+right*math.cos(a)*widths[i]/2+up*math.sin(a)*heights[i]/2 end
 end
 for i=1,#centers-1 do
  local vertices={}; for _,v in rings[i] do table.insert(vertices,v) end; for _,v in rings[i+1] do table.insert(vertices,v) end
  local faces={{1,2,3},{9,10,11}}
  for j=1,8 do local k=j%8+1; table.insert(faces,{j,j+8,k}); table.insert(faces,{k,j+8,k+8}) end
  q.solid(name,vertices,faces,col,limb)
 end
end
loft("Body",{V(0,2.81,-1.51),V(0,2.73,-.96),V(0,2.59,.48),V(0,2.41,1.76),V(0,2.37,2.02)},{1.37,2.56,2.8,1.87,.82},{1.65,2.63,2.65,1.98,1.03},rust,t)
loft("UprightNeck",{V(0,2.9,-1.04),V(0,3.72,-1.41),V(0,4.72,-1.72),V(0,5.15,-1.78)},{1.76,1.44,1.21,1.26},{1.58,1.44,1.22,1.2},warm,t)
q.seg("GoldenThroat",V(0,2.28,-1.79),V(0,4.78,-2.12),1.49,.22,.79,.2,amber,t)
for i=0,5 do
 local y=2.17+i*.47; local z=-1.72-i*.113; local w=1.54-i*.12
 q.tri("BellyPlate",V(-w/2,y+.29,z),V(w/2,y+.29,z),V(0,y-.06,z-.14),i%2==0 and amber or amber:Lerp(cream,.15),t)
 q.tri("BellyFill",V(-w/2,y+.29,z),V(0,y-.06,z-.14),V(-w*.38,y-.03,z),amber,t)
 q.tri("BellyFill",V(w/2,y+.29,z),V(w*.38,y-.03,z),V(0,y-.06,z-.14),amber,t)
end
local h=q.l("Head",V(0,4.84,-1.74))
loft("BigHead",{V(0,5.48,-1.39),V(0,5.65,-1.9),V(0,5.58,-2.56),V(0,5.24,-2.98)},{1.37,2.22,2.2,1.56},{1.58,2.04,1.87,1.08},warm,h)
loft("Snout",{V(0,5.05,-2.67),V(0,4.94,-3.33),V(0,4.95,-3.63)},{1.56,1.54,1.26},{.84,.65,.51},warm,h)
loft("LowerJaw",{V(0,4.71,-2.49),V(0,4.58,-3.1),V(0,4.6,-3.46)},{1.37,1.34,1.03},{.36,.34,.18},amber,h)
local function eye(n,size,cf,col)
 local p=q.d(n,size,cf,col,h); p.Shape=Enum.PartType.Ball; p:SetAttribute("KeepSeparate",true); return p
end
for _,s in {-1,1} do
 local e=q.d("Eye",V(.14,.22,.61),CF(s*1.057,5.65,-2.43)*CFrame.Angles(math.rad(-16),s*.12,0),C(255,163,34),h)
 e:SetAttribute("KeepSeparate",true)
 local p=q.d("SlitPupil",V(.035,.23,.075),CF(s*1.139,5.65,-2.46)*CFrame.Angles(math.rad(-16),0,0),ink,h)
 p:SetAttribute("KeepSeparate",true)
 q.seg("FierceBrow",V(s*1.005,5.78,-2.82),V(s*1.02,6.0,-1.98),.29,.26,.37,.35,shade,h)
 q.sp("Fang",V(s*.56,4.75,-3.2),V(s*.54,4.38,-3.28),.16,cream,h)
 q.b("Mouth",V(s*.69,4.73,-3.36),V(s*.77,4.8,-2.89),.025,shade,h)
 eye("Nostril",V(.045,.105,.15),CF(s*.655,5.12,-3.37),shade)
 q.sp("Horn",V(s*.73,6.36,-1.58),V(s*1.05,7.14,-.91),.57,cream,h)
 q.sp("SideHorn",V(s*.94,5.58,-1.37),V(s*1.67,5.81,-.96),.44,amber,h)
 for i=1,3 do q.sp("CheekScale",V(s*.78,5.32-i*.2,-1.38),V(s*(1.2-i*.08),5.16-i*.19,-.73),.47,shade,h) end
 for _,front in {true,false} do
  local z=front and -1.06 or 1.31; local x=s*(front and .98 or 1.05)
  local l=q.l((s<0 and "Left" or "Right")..(front and "FrontLeg" or "HindLeg"),V(x,2.7,z))
  loft("Thigh",{V(x,2.78,z),V(x*1.19,2.23,z+.06),V(x*1.18,1.42,z+.27)},{.68,1.19,.72},{.91,1.41,.83},rust,l)
  loft("Shin",{V(x*1.18,1.55,z+.24),V(x*1.25,.79,z-.12),V(x*1.24,.4,z-.31)},{.7,.65,.72},{.75,.66,.47},warm,l)
  loft("Paw",{V(x*1.24,.35,z-.05),V(x*1.24,.31,z-.63),V(x*1.24,.29,z-.95)},{.64,1.04,.99},{.54,.54,.4},warm,l)
  for j=1,3 do
   q.seg("ToeClaw",V(x*1.24+(j-2)*.3,.29,z-.88),V(x*1.24+(j-2)*.33,.2,z-1.2),.21,.34,.17,.25,cream,l)
  end
 end
 local a=V(s*.93,3.81,.01); local elbow=V(s*1.75,4.84,.22); local top=V(s*2.15,7.0,.71)
 local tip=V(s*5.33,6.03,1.24)
 local l=q.l((s<0 and "Left" or "Right").."Wing",a)
 loft("WingArm",{a,elbow,top},{.44,.38,.3},{.5,.43,.32},shade,l)
 loft("LeadingEdge",{top,V(s*3.6,6.88,.91),tip},{.34,.26,.035},{.34,.25,.05},warm,l)
 local edges={tip,V(s*4.32,5.56,1.04),V(s*4.15,4.96,.89),V(s*4.4,4.54,.82),V(s*3.55,4.47,.65),V(s*3.08,3.98,.42),V(s*2.99,3.44,.31),V(s*2.51,3.78,.13),V(s*1.96,3.79,.02),a}
 for i=1,#edges-1 do q.tri("WingMembrane",top,edges[i],edges[i+1],i%3==0 and amber:Lerp(cream,.17) or amber,l) end
 for _,i in {1,4,7,10} do q.b("WingFinger",top,edges[i],i==10 and .15 or .11,warm,l) end
 q.sp("WingKnuckle",top,top+V(s*.17,.32,-.15),.35,amber,l)
end
local tail=q.l("Tail",V(0,2.42,1.76))
local tp={V(0,2.42,1.76),V(0,1.97,2.77),V(-.25,1.63,3.74),V(-.93,1.79,4.64),V(-1.59,2.38,5.24),V(-1.9,3.22,5.23)}
loft("CurledTail",tp,{1.1,.85,.64,.49,.31,.08},{1.05,.84,.64,.49,.31,.09},warm,tail)
q.sp("TailFlame",tp[6]-V(0,.16,0),tp[6]+V(-.36,.79,-.05),.64,amber,tail)
q.sp("TailFlameSide",tp[6]-V(0,.12,0),tp[6]+V(.27,.42,.06),.4,warm,tail)
for i=2,5 do q.sp("TailSpine",tp[i]+V(0,.2,0),tp[i]+V(0,.65,.15),.31,amber,tail) end
for i=1,6 do q.sp("BackSpine",V(0,3.7-i*.1,-.39+i*.37),V(0,4.18-i*.13,-.16+i*.37),.43,amber,t) end
for i=1,3 do q.sp("HeadCrest",V(0,6.44,-1.54-i*.25),V(0,6.93-i*.06,-1.34-i*.25),.37,warm,h) end
-- Temporary face wedges are baked into one solid section per rigid limb.
-- All source geometry is discarded only after its union succeeds.
local groups={}
m.Parent=game:GetService("ServerStorage")
for _,p in m:GetChildren() do if p:IsA("BasePart") and p.Transparency==0 and not p:GetAttribute("KeepSeparate") then
 local w=assert(p:FindFirstChildWhichIsA("WeldConstraint")); local l=w.Part0
 groups[l]=groups[l] or {}; table.insert(groups[l],p)
end end
for l,parts in groups do
 local first=parts[1]; local rest={}; for i=2,#parts do table.insert(rest,parts[i]) end
 local u=first:UnionAsync(rest,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Precise)
 u.Name=l.Name.."_Geometry"; u.UsePartColor=false; u.Anchored=true; u.CanCollide=false; u.Massless=true
 for _,c in u:GetChildren() do if c:IsA("WeldConstraint") then c:Destroy() end end
 u.Parent=m
 local w=Instance.new("WeldConstraint",u); w.Part0=l; w.Part1=u
 for _,p in parts do p:Destroy() end
 print("Consolidated",l.Name,#parts)
end
local low=math.huge
for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
end end
m.Humanoid.HipHeight=2.55-m.PrimaryPart.Size.Y/2-low+.025
m:PivotTo(CF(45,2.55-low+.025,125))
for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
m:SetAttribute("Purpose","Low-part reference-inspired Ember Drake review model")
m:SetAttribute("PartBudget",100)
m.Parent=workspace
local count=0; for _,p in m:GetDescendants() do if p:IsA("BasePart") then count+=1 end end
assert(count<=100,"Part budget exceeded")
print("Created",m.Name,"parts",count)
game:GetService("Selection"):Set({})
local cf=m:GetBoundingBox(); workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(13,6,-20),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)

