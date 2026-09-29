"""Author six low-part rectangular eggs as a Rojo-owned Roblox model file."""
from pathlib import Path
import math
import xml.etree.ElementTree as E

ROOT = Path(__file__).resolve().parents[2]
tree = E.Element('roblox', version='4')
folder = E.SubElement(tree, 'Item', {'class': 'Folder'})
def prop(parent, tag, name, value):
    node = E.SubElement(parent, tag, name=name); node.text = str(value); return node
prop(E.SubElement(folder, 'Properties'), 'string', 'Name', 'EggTemplates')
serial = 0
counts = {}
def rgb(hexcode):
    return tuple(int(hexcode[i:i+2],16)/255 for i in (0,2,4))
def egg(name, shell, trim, lid):
    global model, origin, count
    model=E.SubElement(folder,'Item',{'class':'Model'}); p=E.SubElement(model,'Properties')
    prop(p,'string','Name',name);prop(p,'bool','Archivable','true')
    count=0;origin=(0,-55,0)
    root=part('Shell',(3.4,2.8,3.05),(0,1.8,0),shell,studs=True)
    prop(p,'Ref','PrimaryPart',root)
    part('LowerBevel',(3.05,.4,2.75),(0,.2,0),trim)
    part('Shoulder',(3.65,.3,3.3),(0,3.15,0),trim)
    part('SteppedCap',(2.95,.48,2.65),(0,3.52,0),lid,studs=True)
    part('TopStep',(2.25,.23,1.95),(0,3.88,0),lid,studs=True)
def part(name,size,pos,color,angle=0,axis='z',kind='Part',studs=False,neon=False):
    global serial,count
    serial+=1;count+=1;ref=f'RBX{serial}'
    item=E.SubElement(model,'Item',{'class':kind,'referent':ref});p=E.SubElement(item,'Properties')
    prop(p,'string','Name',name)
    v=E.SubElement(p,'Vector3',name='Size')
    for k,n in zip('XYZ',size): E.SubElement(v,k).text=str(n)
    f=E.SubElement(p,'CoordinateFrame',name='CFrame')
    for k,n,o in zip('XYZ',pos,origin):E.SubElement(f,k).text=str(n+o)
    c=math.cos(math.radians(angle));s=math.sin(math.radians(angle))
    r={'z':(c,-s,0,s,c,0,0,0,1),'y':(c,0,s,0,1,0,-s,0,c),'x':(1,0,0,0,c,-s,0,s,c)}[axis]
    for k,n in zip(('R00','R01','R02','R10','R11','R12','R20','R21','R22'),r):E.SubElement(f,k).text=str(n)
    col=E.SubElement(p,'Color3',name='Color');
    for k,n in zip('RGB',rgb(color)):E.SubElement(col,k).text=str(n)
    for name2,val in [('Anchored','true'),('CanCollide','false'),('CanTouch','false'),('Massless','true')]:prop(p,'bool',name2,val)
    prop(p,'token','Material',288 if neon else 256)
    if kind=='Part':prop(p,'token','shape',1)
    for face in ('Top','Bottom','Front','Back','Left','Right'):
        prop(p,'token',face+'Surface',3 if studs and face in ('Top','Front','Back','Left','Right') else 0)
    return ref
def gem(name,pos,color,size=.65):
    part(name,(size,size,.18),pos,color,45,neon=True)
def finish(name):
    assert count<=40,(name,count)
    counts[name]=count

egg('prototype_egg','DAC7A2','927046','F3E8CF')
part('FrontBelt',(3.46,.3,.12),(0,1.05,-1.56),'AE8854')
part('BackBelt',(3.46,.3,.12),(0,1.05,1.56),'AE8854')
part('SeedSeal',(.7,.85,.2),(0,1.95,-1.63),'9C753F',45)
part('SealInset',(.37,.45,.23),(0,1.95,-1.7),'FFE2A0',45)
part('SproutStem',(.14,.55,.15),(.45,4.2,0),'62773C',-12)
part('SproutLeaf',(.72,.18,.36),(.16,4.37,0),'9DB75B',-28)
part('SproutLeaf',(.7,.18,.36),(.75,4.53,0),'768C42',28)
finish('prototype_egg')

egg('advanced_egg','275F6B','193E50','498C98')
for x in (-1.12,1.12):
    part('ElementColumn',(.3,2.2,.14),(x,1.8,-1.59),'EA8F3E')
    part('Crystal',(.55,1.45,.65),(x*.7,4.42,0),'80DCE8',-x*16)
    angle=-x*16;delta=.98
    part('CrystalPoint',(.55,.6,.65),(x*.7-math.sin(math.radians(angle))*delta,4.42+math.cos(math.radians(angle))*delta,0),'B5F5F8',angle,kind='WedgePart')
gem('ElementCore',(0,2,-1.65),'63E5F1',.9)
for x in (-1,1):
    part('EmberVent',(.16,.7,1.5),(x*1.75,1.65,0),'FFA552',neon=True)
finish('advanced_egg')

egg('elite_egg','76549E','DDBA65','A78BCC')
for sign in (-1,1):
    part('HornBase',(.62,.7,.65),(sign*1.25,3.8,.15),'E6CA86',-sign*25)
    part('HornSweep',(.42,.7,.46),(sign*1.58,4.33,.15),'F5DFA5',sign*16)
    part('HornTip',(.3,.6,.33),(sign*1.45,4.83,.15),'FFF0CB',sign*28,kind='WedgePart')
    part('MythicFlank',(.2,1.3,1.15),(sign*1.77,2.1,0),'AA86CE')
part('Crest',(.9,1.15,.16),(0,2,-1.63),'E8C474',45)
gem('CrestHeart',(0,2,-1.74),'F2B8FF',.65)
finish('elite_egg')

egg('master_egg','536259','B1996D','798373')
for sign in (-1,1):
    part('StoneBrace',(.42,2.5,3.25),(sign*1.5,1.75,0),'414A43')
    part('AncientHorn',(.6,.95,.65),(sign*1.35,4.22,0),'CBB891',-sign*25,kind='WedgePart')
    part('FossilTusk',(.24,.8,.3),(sign*.55,1.18,-1.74),'E8DBC0',-sign*15,kind='WedgePart')
part('FossilMask',(1.65,1.15,.26),(0,2.12,-1.68),'CBBB96')
part('FossilBrow',(1.82,.28,.35),(0,2.65,-1.76),'E2D4B3')
for sign in (-1,1):part('FossilEye',(.42,.3,.07),(sign*.46,2.15,-1.84),'1F302D',sign*12)
part('FossilNose',(.3,.33,.1),(0,1.86,-1.86),'1F302D',45)
for z in (-.8,0,.8):part('DorsalPlate',(.62,.75,.48),(0,4.32,z),'B19F78',kind='WedgePart')
finish('master_egg')

egg('supreme_egg','ECEAD8','D6AA48','FFF4D6')
for sign in (-1,1):
    for i in range(3):
        part('GoldenWing',(.4,1.3-i*.18,.45),(sign*(1.85+i*.34),3.1+i*.3,.1),'DAB95E',-sign*32)
        part('IvoryFeather',(.23,1.06-i*.18,.48),(sign*(1.85+i*.34),3.22+i*.3,-.05),'FFF5DE',-sign*32)
gem('DivineSeal',(0,2,-1.69),'FFE7A4',.8)
for x in (-1,1):part('HaloPillar',(.14,.75,.14),(x*.72,4.27,.2),'D6AA48')
for x in (-1,1):part('SquareHaloSide',(.16,1.4,.2),(x*.8,5.05,.2),'FFE5A1',neon=True)
for y in (4.35,5.75):part('SquareHaloBar',(1.76,.16,.2),(0,y,.2),'FFE5A1',neon=True)
finish('supreme_egg')

egg('ultimate_egg','292447','5D4A96','48426E')
for sign in (-1,1):
    part('NebulaSeam',(.15,2.55,.16),(sign*1.36,1.78,-1.57),'B184F6',neon=True)
angle=math.radians(-20)
def orbit(name,size,x,y):
    part(name,size,(x*math.cos(angle)-y*math.sin(angle),2.55+x*math.sin(angle)+y*math.cos(angle),.2),'75D9EF',-20,neon=True)
for sign in (-1,1):orbit('OrbitSide',(.16,4.4,.18),sign*2.2,0)
for sign in (-1,1):orbit('OrbitBar',(4.56,.16,.18),0,sign*2.2)
gem('VoidCore',(0,2,-1.67),'DB86F2',1.15)
gem('VoidPupil',(0,2,-1.8),'F3DDFF',.48)
part('CrownShard',(.65,1.15,.65),(0,4.55,0),'B5A4F7',kind='WedgePart')
for x,y in ((-.85,2.8),(.95,1.1)):
    part('Star',(.45,.12,.1),(x,y,-1.68),'DFD5FF',neon=True)
    part('Star',(.12,.45,.1),(x,y,-1.68),'DFD5FF',neon=True)
finish('ultimate_egg')

def effect(shell,name,position,color,rate,texture='sparkles_main.dds',size=.32,speed=.7,life=1.6,spread=45,opacity=.15):
    # The first Studio pass showed tiny premium sparkles disappearing at belt distance.
    tier=model.find("Properties/string[@name='Name']").text
    if texture=='sparkles_main.dds' and tier!='prototype_egg':
        size*=1.5
    anchor=E.SubElement(shell,'Item',{'class':'Attachment'})
    ap=E.SubElement(anchor,'Properties');prop(ap,'string','Name',name+'Origin')
    cf=E.SubElement(ap,'CoordinateFrame',name='CFrame')
    for k,n in zip('XYZ',position):E.SubElement(cf,k).text=str(n)
    for i in range(3):
        for j in range(3):E.SubElement(cf,f'R{i}{j}').text=str(int(i==j))
    emitter=E.SubElement(anchor,'Item',{'class':'ParticleEmitter'})
    p=E.SubElement(emitter,'Properties');prop(p,'string','Name',name)
    prop(p,'bool','Enabled','true');prop(p,'bool','LockedToPart','true')
    prop(p,'float','Rate',rate);prop(p,'float','LightEmission',.7)
    prop(p,'float','LightInfluence',0);prop(p,'float','Drag',.4)
    prop(p,'NumberRange','Lifetime',f'{life*.65} {life}')
    prop(p,'NumberRange','Speed',f'{speed*.5} {speed}')
    prop(p,'NumberRange','Rotation','0 360');prop(p,'NumberRange','RotSpeed','-35 35')
    prop(p,'NumberSequence','Size',f'0 0 0 .18 {size} 0 .65 {size*.65} 0 1 0 0')
    prop(p,'NumberSequence','Transparency',f'0 1 0 .12 {opacity} 0 .65 {min(1,opacity+.2)} 0 1 1 0')
    r,g,b=rgb(color);prop(p,'ColorSequence','Color',f'0 {r} {g} {b} 0 1 {r*.8} {g*.9} {b} 0')
    content=E.SubElement(p,'Content',name='Texture');E.SubElement(content,'url').text='rbxasset://textures/particles/'+texture
    v=E.SubElement(p,'Vector2',name='SpreadAngle');E.SubElement(v,'X').text=str(spread);E.SubElement(v,'Y').text=str(spread)
    prop(p,'token','EmissionDirection',1)
    return anchor

for model in folder.findall('Item'):
    name=model.find("Properties/string[@name='Name']").text
    shell=model.find("Item[@class='Part']")
    if name=='prototype_egg':
        effect(shell,'GoldenPollen',(.4,2.7,0),'FFE1A0',3,size=.18,life=2,spread=70)
        effect(shell,'SproutFireflies',(-1.8,.5,-.6),'B9DE82',2,size=.14,life=2.2,spread=90)
    elif name=='advanced_egg':
        effect(shell,'FrostCrystals',(-.85,3.7,0),'9DF4FF',6,size=.3,speed=1,spread=35)
        effect(shell,'EmberSparks',(1.85,.2,0),'FFAC54',5,size=.2,speed=1.7,life=1.2,spread=30)
        effect(shell,'ColdMist',(-1.85,.3,0),'81DDEB',2,texture='smoke_main.dds',size=.7,speed=.35,opacity=.85)
        effect(shell,'CorePulse',(0,.2,-1.78),'9AEFFF',1,texture='flare_main.dds',size=.8,speed=0,life=2,opacity=.7)
    elif name=='elite_egg':
        effect(shell,'HornWisps',(-1.55,3.1,0),'DEADFF',5,size=.32,speed=.7,spread=40)
        effect(shell,'HornWisps',(1.55,3.1,0),'F8D887',5,size=.25,speed=.7,spread=40)
        effect(shell,'EnchantedDust',(0,1.65,-1.85),'C895FF',5,size=.14,speed=.8,spread=110)
        effect(shell,'CrestBloom',(0,.2,-1.85),'DFB5FF',1,texture='flare_main.dds',size=1,speed=0,life=2,opacity=.78)
    elif name=='master_egg':
        effect(shell,'AncientDust',(-1.85,-.8,0),'D0B483',4,texture='smoke_main.dds',size=.65,speed=.4,opacity=.88)
        effect(shell,'AncientDust',(1.85,-.8,0),'D0B483',4,size=.16,speed=.8,spread=70)
        effect(shell,'SoulEmbers',(0,2.7,0),'A8E8BC',7,size=.27,speed=.55,life=2.2,spread=60)
        effect(shell,'FossilGlints',(0,.45,-1.92),'E4DBA9',3,size=.19,speed=.5,spread=100)
    elif name=='supreme_egg':
        for x in (-2.3,2.3):effect(shell,'WingStardust',(x,1.9,0),'FFF1BE',6,size=.3,speed=.6,life=1.8,spread=80)
        effect(shell,'HaloStars',(0,4,0),'FFF6D7',6,size=.42,speed=.5,life=2,spread=90)
        effect(shell,'DivineMist',(0,2.25,0),'FFE5A2',2,texture='smoke_main.dds',size=1.1,speed=.3,opacity=.9)
        effect(shell,'SealRadiance',(0,.2,-1.88),'FFF1C3',2,texture='flare_main.dds',size=1.15,speed=0,life=2,opacity=.77)
    else:
        for x in (-2.2,2.2):effect(shell,'OrbitStardust',(x,.8,.2),'8CEAFF',7,size=.23,speed=.7,life=2.1,spread=110)
        effect(shell,'CrownStars',(0,3.2,0),'E7BDFF',7,size=.4,speed=.7,life=2,spread=75)
        effect(shell,'NebulaVeil',(0,2.5,.4),'AC80EB',3,texture='smoke_main.dds',size=1.15,speed=.3,opacity=.88)
        effect(shell,'VoidCoreBloom',(0,.2,-1.98),'DC9DF8',2,texture='flare_main.dds',size=1.25,speed=0,life=2,opacity=.78)
        effect(shell,'FallingStars',(0,3.4,-1.65),'C8EFFF',5,size=.16,speed=1.5,life=1.5,spread=130)
    if name in ('supreme_egg','ultimate_egg'):
        light=E.SubElement(shell,'Item',{'class':'PointLight'});p=E.SubElement(light,'Properties')
        prop(p,'string','Name','EggGlow');prop(p,'float','Brightness',.45);prop(p,'float','Range',7);prop(p,'bool','Shadows','false')
        v=E.SubElement(p,'Color3',name='Color')
        for k,n in zip('RGB',rgb('FFE3A2' if name=='supreme_egg' else 'BC9AFF')):E.SubElement(v,k).text=str(n)

E.indent(tree,space='  ')
E.ElementTree(tree).write(ROOT/'src/world/EggTemplates.rbxmx',encoding='utf-8',xml_declaration=True)
print(counts)
