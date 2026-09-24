import bpy, math
from mathutils import Vector
rig=bpy.data.objects['Kitsune Rig']
for o in list(bpy.data.objects):
 if o.type!='MESH' or o.parent!=rig:continue
 if o.name.startswith(('Tail','Cheek feather','Layered chest','Shoulder coat','Ear fluff')):
  sub=o.modifiers.new('Soft sculpted fur','SUBSURF');sub.levels=2;sub.render_levels=2
 if o.name.startswith('Layered chest'):
  o.location.y-=.25
 if o.name.startswith('Tail') and 'plume' in o.name:
  # Pull last ring outward for pointed, hooked tips; preceding ring narrows.
  verts=o.data.vertices
  center=sum((v.co for v in verts[-16:]),Vector())/16
  prior=sum((v.co for v in verts[-32:-16]),Vector())/16
  direction=(center-prior).normalized()
  for v in verts[-16:]:v.co+=direction*.25
  for v in verts[-32:-16]:v.co=prior+(v.co-prior)*.7
# fill center of the bib using copies of existing tufts, bound to torso.
base=bpy.data.objects['Layered chest fur.002']
for row in range(3):
 o=base.copy();o.data=base.data.copy();bpy.context.collection.objects.link(o);o.name='Center bib feather'
 for key in list(o.keys()):del o[key]
 o.location.x=0;o.location.y=-1.16+row*.05;o.location.z=base.location.z-row*.19
 for v in o.vertex_groups:o.vertex_groups.remove(v)
 vg=o.vertex_groups.new(name='Spine');vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
scene=bpy.context.scene
scene.render.resolution_x=640;scene.render.resolution_y=640
target=artifacts.file(name='kitsune-refined.png',media_type='image/png');scene.render.filepath=str(target.path);bpy.ops.render.render(write_still=True);target.publish()
result={'refined':'Tapered smoothed tails, visible layered chest fur','bones':len(rig.data.bones)}
