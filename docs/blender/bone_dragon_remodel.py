# Connection map (metres): ribs overlap spine by >= .025; neck overlaps spine
# and skull by >= .06; jaw overlaps skull hinge by .08; horns overlap skull .06;
# limb chains overlap joint spheres .06; toes overlap paws .06; wing spars
# overlap shoulder sockets .08 and share membrane edges; tail overlaps pelvis .08.
# Feet sit on z=0. Geometry is built at explicit coordinates, no cylinder Euler rotations.
import bpy, bmesh, math
from mathutils import Vector

parts=[]
bounds={}
def material(name,color,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=.62;p.inputs['Metallic'].default_value=metal
    return m
bone=material('Warm ivory bone',(.74,.64,.43))
light=material('Skull highlight',(.95,.86,.65))
dark=material('Obsidian wing membrane',(.035,.055,.085))
shadow=material('Deep eye socket',(.014,.022,.027))
cyan=material('Soul turquoise',(.02,.85,.76),.15)
gold=material('Ancient bronze',(.31,.19,.075),.25)
def verify(o):
    bpy.context.view_layer.update()
    vs=[o.matrix_world@v.co for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in vs) for i in range(3)))
    hi=Vector(tuple(max(v[i] for v in vs) for i in range(3)))
    bounds[o.name]=(lo,hi)
    return lo,hi
def register(o,name,mat,group):
    o.name=name;o.data.materials.append(mat);o['rig_section']=group
    o.vertex_groups.new(name=group).add(list(range(len(o.data.vertices))),1,'REPLACE')
    parts.append(o);verify(o);return o
def ell(name,at,size,mat,group):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=at)
    o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return register(o,name,mat,group)
def beam(name,a,b,r1,r2,mat,group,n=8):
    a,b=Vector(a),Vector(b);d=(b-a).normalized()
    u=d.cross(Vector((0,0,1)) if abs(d.z)<.95 else Vector((1,0,0))).normalized();v=d.cross(u)
    bm=bmesh.new();rings=[]
    for p,r in [(a,r1),(b,r2)]:
        rings.append([bm.verts.new(p+r*(math.cos(i*2*math.pi/n)*u+math.sin(i*2*math.pi/n)*v)) for i in range(n)])
    for i in range(n):bm.faces.new([rings[0][i],rings[0][(i+1)%n],rings[1][(i+1)%n],rings[1][i]])
    bm.faces.new(list(reversed(rings[0])));bm.faces.new(rings[1])
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    me=bpy.data.meshes.new(name);bm.to_mesh(me);bm.free();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return register(o,name,mat,group)
def poly(name,verts,faces,mat,group):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return register(o,name,mat,group)
def contact(a,b):
    la,ha=verify(a);lb,hb=verify(b)
    assert all(min(ha[i],hb[i])-max(la[i],lb[i])>=.005 for i in range(3)), 'Disconnected '+a.name+' '+b.name

# Forward is -Y; broad skull and expressive soul eyes define the silhouette.
spine=beam('Spine',(0,-.65,1.65),(0,1.0,1.5),.22,.26,bone,'Torso')
pelvis=ell('Pelvis',(0,.84,1.44),(.45,.38,.33),bone,'Torso');contact(spine,pelvis)
neck=beam('Upright neck',(0,-.58,1.64),(0,-1.02,2.34),.24,.20,bone,'Neck');contact(spine,neck)
skull=ell('Dragon skull',(0,-1.35,2.48),(.52,.61,.40),light,'Skull');contact(neck,skull)
muzzle=ell('Broad muzzle',(0,-1.81,2.34),(.40,.42,.23),light,'Skull');contact(skull,muzzle)
jaw=ell('Lower jaw',(0,-1.63,2.14),(.36,.52,.105),bone,'Skull');contact(skull,jaw)
for s in [-1,1]:
    ell('Eye socket '+str(s),(s*.455,-1.47,2.53),(.08,.255,.16),shadow,'Skull')
    ell('Soul eye '+str(s),(s*.514,-1.54,2.55),(.03,.105,.086),cyan,'Skull')
    beam('Heavy brow '+str(s),(s*.41,-1.72,2.69),(s*.51,-1.19,2.69),.10,.075,light,'Skull')
    horn=beam('Crown horn '+str(s),(s*.33,-1.08,2.72),(s*.58,-.60,3.22),.17,.025,bone,'Skull');contact(skull,horn)
    beam('Horn tip '+str(s),(s*.58,-.60,3.20),(s*.66,-.37,3.35),.06,.004,light,'Skull')
    beam('Cheek spike '+str(s),(s*.40,-1.02,2.42),(s*.75,-.65,2.50),.12,.004,bone,'Skull')
    for i in range(3):
        beam('Fang '+str(s)+' '+str(i),(s*(.20+i*.07),-1.97+i*.15,2.23),(s*(.20+i*.07),-1.97+i*.15,2.06),.047,.008,light,'Skull',6)
    ell('Nostril '+str(s),(s*.18,-2.17,2.39),(.072,.025,.052),shadow,'Skull')

# Five readable open rib arcs instead of hundreds of tiny bone fragments.
for i,y in enumerate([-.52,-.22,.10,.42,.71]):
    width=.54 if i in [1,2] else .46
    for s in [-1,1]:
        points=[(0,y,1.69),(s*width,y,1.47),(s*(width+.04),y,1.08),(s*.20,y,.98)]
        for j in range(3):beam('Rib %s %s %s'%(i,s,j),points[j],points[j+1],.068,.063,light,'Torso',6)
    beam('Dorsal crest '+str(i),(0,y,1.75),(0,y+.12,2.08 if i<3 else 1.94),.11,.004,bone,'Torso',6)
beam('Sternum',(0,-.58,1.0),(0,.72,1.0),.11,.11,bone,'Torso')

rig={'Torso':((0,0,1.45),(0,0,1.9),None),'Neck':((0,-.58,1.64),(0,-1.02,2.34),'Torso'),'Skull':((0,-1.02,2.34),(0,-1.75,2.44),'Neck')}
for s,label in [(-1,'Left'),(1,'Right')]:
    for front,y in [(True,-.45),(False,.76)]:
        group=label+('Foreleg' if front else 'Hindleg')
        a=(s*.43,y,1.47);b=(s*.65,y+.11,.79);c=(s*.68,y-.11,.25)
        rig[group]=(a,c,'Torso')
        socket=ell(group+' joint',a,(.25,.23,.25),bone,group)
        upper=beam(group+' upper',a,b,.19,.135,bone,group);contact(socket,upper)
        knee=ell(group+' knee',b,(.17,.17,.17),light,group);contact(upper,knee)
        lower=beam(group+' shin',b,c,.13,.11,light,group);contact(knee,lower)
        paw=ell(group+' paw',(c[0],c[1]-.13,.14),(.23,.31,.14),bone,group);contact(lower,paw)
        for t in [-1,0,1]:beam(group+' claw '+str(t),(c[0]+t*.13,c[1]-.27,.14),(c[0]+t*.15,c[1]-.55,.035),.075,.008,light,group,6)
    group=label+'Wing';root=(s*.24,-.35,1.8);elbow=(s*1.1,-.03,2.52);tip=(s*2.4,.06,2.94)
    rig[group]=(root,elbow,'Torso')
    shoulder=ell(group+' socket',root,(.22,.22,.22),bone,group)
    spar=beam(group+' arm',root,elbow,.15,.11,bone,group);contact(shoulder,spar)
    beam(group+' leading spar',elbow,tip,.11,.015,light,group)
    # Two-sided solid membrane: shallow thickness, sealed back faces.
    outline=[elbow,tip,(s*2.03,.67,1.94),(s*1.68,.55,2.07),(s*1.35,1.06,1.48),(s*.97,.79,1.68),(s*.49,.92,1.43),root]
    verts=outline+[(x,y+.018,z)for x,y,z in outline]
    faces=[]
    for j in range(1,7):faces.extend([(0,j,j+1),(8,8+j+1,8+j)])
    for j in range(8):faces.append((j,(j+1)%8,(j+1)%8+8,j+8))
    poly(group+' membrane',verts,faces,dark,group)
    for j in [2,4,6]:beam(group+' finger '+str(j),elbow,outline[j],.047,.015,bone,group,6)
    beam(group+' thumb',elbow,(s*1.18,-.30,2.87),.08,.004,light,group,6)

tailpts=[(0,1.0,1.47),(0,1.52,1.20),(.16,2.04,.90),(.37,2.51,.69),(.69,2.88,.79)]
rig['Tail']=(tailpts[0],tailpts[1],'Torso')
for i in range(4):
    beam('Tail vertebra '+str(i),tailpts[i],tailpts[i+1],.20-i*.04,.16-i*.038,bone,'Tail')
    p=Vector(tailpts[i]);beam('Tail crest '+str(i),p,p+Vector((0,.12,.28-i*.04)),.10-i*.015,.004,light,'Tail',6)
beam('Tail blade',tailpts[-2],(.80,3.05,.99),.13,.005,light,'Tail',6)

# Finalize clean transforms, preserving named rigid skin groups.
for o in parts:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY',center='MEDIAN')
    bpy.ops.object.shade_smooth()
    assert all(abs(x-1)<1e-5 for x in o.scale) and all(abs(x)<1e-5 for x in o.rotation_euler)
    verify(o)
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();skin=bpy.context.object;skin.name='BoneDragon_SkinnedMesh'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
skin.data.calc_loop_triangles();triangles=len(skin.data.loop_triangles)
assert triangles<10000, triangles
bpy.ops.object.select_all(action='DESELECT');ad=bpy.data.armatures.new('BoneDragon_Rig');arm=bpy.data.objects.new('BoneDragon_Rig',ad);bpy.context.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,(head,tail,parent) in rig.items():
    b=ad.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=ad.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');mod=skin.modifiers.new('Rigid pet skin','ARMATURE');mod.object=arm;skin.parent=arm
arm['Purpose']='Rigid limb rig; rest pose export. Roblox import still required.'
assert len(ad.bones)==10
assert all(len(v.groups)==1 for v in skin.data.vertices)

scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE'
if scene.world is None:scene.world=bpy.data.worlds.new('Ambient world')
scene.world.color=(.22,.22,.22)
def lightobj(name,at,power,color):
    d=bpy.data.lights.new(name,'POINT');d.energy=power;d.color=color;d.shadow_soft_size=3
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=at
lightobj('Warm key',(3,-5,7),1500,(1,.88,.72));lightobj('Cool fill',(-4,-1,4),1000,(.50,.75,1));lightobj('Wing rim',(1,5,6),1600,(.65,1,1))
cd=bpy.data.cameras.new('Delivery camera');cam=bpy.data.objects.new('Delivery camera',cd);bpy.context.collection.objects.link(cam)
cam.location=(6,-8,5);target=Vector((0,.25,1.55));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=7.0;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
target=artifacts.file(name='bone-dragon-remodel.png',media_type='image/png');scene.render.filepath=str(target.path);bpy.ops.render.render(write_still=True);target.publish()
result={'pet':'Bone Dragon','mesh_objects':1,'rig_bones':len(ad.bones),'triangles':triangles,'vertices':len(skin.data.vertices),'dimensions':list(skin.dimensions),'all_vertices_rigid_weighted':True,'status':'Blender draft; Roblox import/visual/gameplay validation pending'}
