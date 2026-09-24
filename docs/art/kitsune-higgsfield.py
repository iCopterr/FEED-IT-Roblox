# Connection map (metres): torso/neck/head overlap >= .12; thighs/torso >= .15;
# shins/thighs and paws/shins >= .08; ears/head >= .10; muzzle/head >= .12;
# fur roots inset .06 into parent; nine tail roots inset .18 into rump.
import bpy, math
from mathutils import Vector
from math import sin, cos, pi
scene=bpy.context.scene
def mat(n,c,rough=.55):
 m=bpy.data.materials.new(n); m.diffuse_color=(*c,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*c,1); p.inputs['Roughness'].default_value=rough
 return m
ivory=mat('Warm ivory fur',(.88,.78,.61))
cream=mat('Cream highlights',(1,.91,.73))
red=mat('Vermilion markings',(.75,.025,.018))
inner=mat('Deep rose ear interior',(.23,.025,.025))
black=mat('Ink eye outlines',(.018,.008,.012),.35)
gold=mat('Golden amber irises',(1,.35,.012),.25)
white=mat('Eye catchlights',(1,.98,.86),.2)
parts=[]; bindings={}
def bounds(o):
 bpy.context.view_layer.update()
 v=[o.matrix_world @ Vector(x) for x in o.bound_box]
 b=[(min(p[i] for p in v),max(p[i] for p in v)) for i in range(3)]
 print(o.name, 'bounds',b); return b
def finish(o,n,m,bone):
 o.name=n; o.data.materials.append(m)
 bpy.context.view_layer.objects.active=o; o.select_set(True)
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY',center='MEDIAN')
 for p in o.data.polygons:p.use_smooth=True
 o.select_set(False); parts.append(o);bindings[o.name]=bone;bounds(o);return o
def ball(n,p,s,m=ivory,bone='Spine'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=p)
 o=bpy.context.object;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,n,m,bone)
def sweep(n,points,radii,m=cream,bone='Head',sides=12):
 pts=[Vector(p) for p in points];verts=[];faces=[]
 for i,p in enumerate(pts):
  tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
  ref=Vector((0,1,0)) if abs(tangent.y)<.9 else Vector((1,0,0))
  u=tangent.cross(ref).normalized();v=tangent.cross(u).normalized()
  r=radii[i];a,b=(r,r) if isinstance(r,(int,float)) else r
  for j in range(sides):
   q=p+u*cos(j*2*pi/sides)*a+v*sin(j*2*pi/sides)*b
   verts.append(tuple(q))
 for i in range(len(pts)-1):
  for j in range(sides):
   a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.append(tuple(reversed(range(sides))));faces.append(tuple((len(pts)-1)*sides+j for j in range(sides)))
 me=bpy.data.meshes.new(n);me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o)
 return finish(o,n,m,bone)
def tuft(n,root,tip,w=.17,m=cream,bone='Head'):
 a=Vector(root);b=Vector(tip);d=b-a
 return sweep(n,[a,a+d*.28,a+d*.62,b],[w*.65,w,w*.65,.004],m,bone)
torso=ball('Torso',(0,.15,1.12),(.59,.94,.59))
ball('Chest',(0,-.53,1.30),(.58,.53,.7))
ball('Neck',(0,-.67,1.75),(.48,.43,.49))
head=ball('Head',(0,-.91,2.15),(.64,.53,.61),cream,'Head')
ball('Muzzle',(0,-1.35,1.99),(.4,.34,.23),cream,'Head')
ball('Chin',(0,-1.31,1.85),(.30,.24,.13),cream,'Head')
ball('Nose',(0,-1.674,2.055),(.105,.065,.073),black,'Head')
for s in [-1,1]:
 for y,label in [(-.54,'Front'),(.76,'Rear')]:
  bone=label+('.L' if s<0 else '.R')
  ball(label+' thigh '+str(s),(s*.42,y,.86),(.25,.28,.47),ivory,bone)
  sweep(label+' shin '+str(s),[(s*.42,y,.82),(s*.43,y-.03,.48),(s*.44,y-.09,.19)],[.18,.135,.12],cream,bone)
  ball(label+' paw '+str(s),(s*.44,y-.18,.14),(.225,.29,.14),cream,bone)
  for j in [-1,0,1]:
   ball(label+' red toe '+str(s)+' '+str(j),(s*.44+j*.11,y-.405,.12),(.056,.077,.08),red,bone)
 # ears are thick tapered volumes, inner volumes deliberately embedded
 sweep('Ear '+str(s),[(s*.40,-.82,2.48),(s*.49,-.78,2.84),(s*.56,-.77,3.22),(s*.59,-.80,3.42)],[(.28,.20),(.235,.16),(.12,.09),.006],red,'Head')
 sweep('Inner ear '+str(s),[(s*.43,-.975,2.62),(s*.50,-.924,2.88),(s*.565,-.865,3.26)],[(.15,.035),(.135,.026),.005],inner,'Head')
 for k in range(3):
  tuft('Ear fluff', (s*(.34+k*.065),-1.00,2.56+k*.12),(s*(.17+k*.10),-1.01,2.86+k*.1),.115)
 # forward-facing stylized eyes, angled by actual vertex placement
 eye=ball('Eye ink '+str(s),(s*.36,-1.346,2.22),(.225,.065,.235),black,'Head')
 ball('Eye amber '+str(s),(s*.365,-1.394,2.22),(.166,.032,.183),gold,'Head')
 ball('Eye pupil '+str(s),(s*.38,-1.42,2.24),(.054,.021,.139),black,'Head')
 ball('Eye sparkle '+str(s),(s*.33,-1.445,2.30),(.042,.015,.055),white,'Head')
 tuft('Upper eye lash',(s*.20,-1.386,2.36),(s*.65,-1.30,2.44),.06,black)
 # swept cheek fur, broad bases
 for k in range(4):
  tuft('Cheek feather '+str(s)+' '+str(k),(s*.42,-1.01,2.19-k*.12),(s*(.84+.045*k),-.94,2.16-k*.17),.18)
 for k in range(2):
  tuft('Cheek scarlet marking',(s*.53,-1.275,2.12-k*.15),(s*.77,-1.09,2.17-k*.15),.07,red)
 # layered ruff
 for row in range(3):
  for j in range(5):
   a=-1.15+j*.49
   x=s*(.15+row*.025+abs(sin(a))*.30)
   y=-.91+cos(a)*.02+abs(x)*.2
   z=1.87-row*.21
   tuft('Layered chest fur',(x,y,z),(x+s*.09,y-.06,z-.43),.145)
 for k in range(5):
  tuft('Shoulder coat',(s*.47,-.35+k*.20,1.57),(s*.67,-.16+k*.2,1.32),.16,ivory,'Spine')
 for k in range(3):
  tuft('Leg flame marking',(s*.48,-.776, .98-k*.18),(s*.54,-.777,.82-k*.18),.055,red,'Front'+('.L' if s<0 else '.R'))
# forehead flame crest
tuft('Central forehead flame',(0,-1.417,2.39),(0,-1.26,2.75),.085,red)
for s in [-1,1]:
 tuft('Forehead flame side',(s*.11,-1.4,2.45),(s*.19,-1.21,2.75),.045,red)
# Nine radial plume tails behind rump, open fan. Each is a single smooth tapered sweep with red tip.
tail_defs=[]
for i in range(9):
 a=(-88+i*22)*pi/180
 end=Vector((sin(a)*1.53,1.48+(.18 if i%2 else 0),1.36+cos(a)*1.67))
 root=Vector((sin(a)*.20,.79,1.15))
 mid=root.lerp(end,.52);mid.y+=.20
 pts=[root,root.lerp(mid,.50),mid,mid.lerp(end,.55),end,end+Vector((sin(a)*.16,-.15,.09))]
 rs=[.17,.26,.36,.32,.18,.005]
 bone='Tail.%02d'%i
 o=sweep('Tail %02d ivory plume'%i,pts,rs,cream,bone,16)
 o.data.materials.append(red)
 for p in o.data.polygons:
  if p.index>=3*16:p.material_index=1
 tail_defs.append((bone,root,end))
 # sparse overlapping broad fur blades following tail, not detached spikes
 tangent=(end-root).normalized()
 for j,t in enumerate([.39,.58,.73]):
  c=root.lerp(end,t);c.y+=.08
  for sign in [-1,1]:
   offset=Vector((cos(a)*sign*.17,-.17,-sin(a)*sign*.17))
   tuft('Tail %02d fur'%i,c+offset*.5,c+offset+tangent*.44,.135,red if t>.7 else cream,bone)
# Simple editable posing rig, full mesh weights; not an animation-ready organic skin.
arm=bpy.data.armatures.new('Kitsune posing skeleton');rig=bpy.data.objects.new('Kitsune Rig',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
def bone(n,h,t,parent=None):
 b=arm.edit_bones.new(n);b.head=h;b.tail=t
 if parent:b.parent=arm.edit_bones[parent]
bone('Root',(0,0,0),(0,0,.5))
bone('Spine',(0,.65,1.1),(0,-.55,1.4),'Root')
bone('Head',(0,-.6,1.7),(0,-.95,2.4),'Spine')
for s in [-1,1]:
 for y,label in [(-.54,'Front'),(.76,'Rear')]:
  bone(label+('.L' if s<0 else '.R'),(s*.42,y,1.05),(s*.44,y-.09,.19),'Spine')
for n,h,t in tail_defs:bone(n,h,t,'Spine')
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
for o in parts:
 vg=o.vertex_groups.new(name=bindings[o.name]);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Pose deformation','ARMATURE');mod.object=rig;o.parent=rig
# studio floor separate from character
floor_mat=mat('Studio sand',(.24,.205,.17))
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object;floor.name='Studio floor';floor.data.materials.append(floor_mat)
bpy.ops.object.camera_add(location=(5,-8,3.8))
cam=bpy.context.object;cam.name='Delivery Camera';cam.rotation_euler=(Vector((0,.25,1.65))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=5.6;scene.camera=cam
for n,loc,power,col,radius in [('Key',(-3,-4,7),1500,(1,.87,.72),3),('Fill',(4,-3,4),850,(.77,.86,1),2.5),('Rim',(0,4,6),1900,(1,.65,.40),2)]:
 d=bpy.data.lights.new(n,'POINT');d.energy=power;d.color=col;d.shadow_soft_size=radius;o=bpy.data.objects.new(n,d);bpy.context.collection.objects.link(o);o.location=loc
scene.world=bpy.data.worlds.new('Studio World')
scene.world.color=(.23,.23,.23)
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.media_type='IMAGE';scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
scene.render.film_transparent=False
scene.frame_start=1;scene.frame_end=120;scene.render.fps=24
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
target=artifacts.file(name='kitsune-three-quarter.png',media_type='image/png');scene.render.filepath=str(target.path);bpy.ops.render.render(write_still=True);target.publish()
result={'meshes':len(parts),'bones':len(arm.bones),'tails':len(tail_defs),'all_weighted':all(len(o.vertex_groups)>0 for o in parts),'clean_transforms':all(tuple(o.scale)==(1,1,1) and sum(abs(v) for v in o.rotation_euler)<.0001 for o in parts)}
