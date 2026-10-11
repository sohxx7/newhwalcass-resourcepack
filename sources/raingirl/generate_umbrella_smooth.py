"""Raingirl v3: curved cloth panels exported as legal 1.21.8 composite items.

Usage: python generate_umbrella_smooth.py STAGING_DIRECTORY
Uses preserved display/hardware from the first backup, never modifies live pack.
Two explicitly textured faces per cloth element; no negative cubes/backface hack.
"""
from pathlib import Path
import json, math, copy, sys, base64, uuid
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT/'pack'
OUT = Path(sys.argv[1]); OUT.mkdir(parents=True, exist_ok=True)
BACK = Path(__file__).resolve().parent/'smooth_baseline'
TEX = 'dor:item/char/raingirl/umbrella_smooth'
OLDTEX = 'dor:item/char/raingirl/umbrella'
PREFIX = 'dor:item/char/raingirl/'
CENTER = np.array([6.,8.,8.5])
CANOPY_SHIFT = np.array([2.,-7.995,-.5])  # Exact original open -> projectile shift.
SLOTS = ['thirdperson_righthand','thirdperson_lefthand','firstperson_righthand','firstperson_lefthand','gui','ground','fixed','head']
ATLAS_SIZE=2048; TILE=256; GUTTER=8; CONTENT=TILE-2*GUTTER; AA=8
ATLAS = Image.new('RGBA',(ATLAS_SIZE,ATLAS_SIZE)); tiles={}
def dump(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def read(name): return json.loads((BACK/'models'/f'{name}.json').read_text(encoding='utf-8'))
def display_base(name):
    base=copy.deepcopy(read(name).get('display',{}))
    grip=np.array([6.,-11.5,8.5])-8
    if name in ['umbrella_open','umbrella_stick']:
        # Keep the canopy to the outer side of the first-person camera.
        # Third-person umbrella pose remains exactly as supplied by the user.
        angles=[-12,0,-18];scale=.30
        translation=-xyz(angles)@(grip*scale)+np.array([2.5,-1.5,0])
        base['firstperson_righthand']={'rotation':angles,'translation':rnd(translation),'scale':[scale]*3}
        base['firstperson_lefthand']={'rotation':[angles[0],-angles[1],-angles[2]],'translation':rnd(translation*np.array([-1,1,1])),'scale':[scale]*3}
    elif name=='umbrella_closed':
        # Huashan/satgat swords: +Y blade, no third-person X rotation.
        # Re-anchor at this umbrella's own grip; do not copy a sword's offsets.
        scale=base['thirdperson_righthand']['scale'][0]
        translation=-grip*scale
        base['thirdperson_righthand']={'rotation':[0,0,0],'translation':rnd(translation),'scale':[scale]*3}
        base['thirdperson_lefthand']={'rotation':[0,0,0],'translation':rnd(translation*np.array([-1,1,1])),'scale':[scale]*3}
    return base
def rnd(v): return [round(float(x),6) for x in v]
def rot(axis,a):
    c=math.cos(math.radians(a));s=math.sin(math.radians(a))
    if axis=='x': return np.array([[1,0,0],[0,c,-s],[0,s,c]])
    if axis=='y': return np.array([[c,0,s],[0,1,0],[-s,0,c]])
    return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def xyz(v):return rot('x',v[0])@rot('y',v[1])@rot('z',v[2])
def euler(m):
    y=math.asin(float(np.clip(m[0,2],-1,1)))
    if abs(math.cos(y))>1e-7:x=math.atan2(-m[1,2],m[2,2]);z=math.atan2(-m[0,1],m[0,0])
    else:x=math.atan2(m[2,1],m[1,1]);z=0
    return rnd(np.degrees([x,y,z]))
def displays(base,phi,center):
    result={}; q=rot('y',phi); delta=center-8
    for slot in SLOTS:
        d=base.get(slot,{}); r=xyz(d.get('rotation',[0,0,0]));s=np.array(d.get('scale',[1,1,1]));t=np.array(d.get('translation',[0,0,0]))
        assert max(s)-min(s)<1e-8, 'Composite transform requires uniform source scale'
        mirror=np.diag([-1,1,1]) if 'lefthand' in slot else np.eye(3)
        target=r@mirror@q@mirror
        result[slot]={'rotation':euler(target),'translation':rnd(t+r@(s*(mirror@delta))),'scale':rnd(s)}
    return result

def tile(poly,color,under=False,hem=False,fold=False):
    key=json.dumps([np.round(poly,5).tolist(),color,under,hem,fold])
    if key in tiles:return tiles[key]
    n=len(tiles);assert n<64
    yy,xx=np.mgrid[0:CONTENT,0:CONTENT];u=(xx+.5)/CONTENT;v=(yy+.5)/CONTENT
    if fold:
        light=.86+.14*np.sin(u*math.pi)+.06*u
    else:
        light=.965+.03*np.sin(u*math.pi)+.016*np.cos(v*math.pi)
    rgb=np.clip(np.array(color)[None,None,:]*light[:,:,None],0,255).astype('uint8')
    # Rasterize the exact trapezoid, without the old 2px outward dilation.
    # Supersampling estimates edge coverage; outside-center samples stay zero
    # even in Minecraft cutout layers, which may use a low alpha threshold.
    l0,r0,r1,l1=poly[:,0]
    left=l0+(l1-l0)*v;right=r0+(r1-r0)*v
    inside=(u>=left)&(u<=right)
    coverage=np.zeros((CONTENT,CONTENT),dtype=float)
    for sy in range(AA):
        sv=(yy+(sy+.5)/AA)/CONTENT
        sl=l0+(l1-l0)*sv;sr=r0+(r1-r0)*sv
        for sx in range(AA):
            su=(xx+(sx+.5)/AA)/CONTENT
            coverage+=(su>=sl)&(su<=sr)
    ar=np.where(inside,np.rint(255*coverage/(AA*AA)),0).astype('uint8')
    if hem:
        rgb[v>.94]=[227,247,251] if not under else [214,237,244]
        rgb[(v>.928)&(v<.94)]=[91,165,193]
    # Draw seam shading INSIDE the mask. Never paint opaque pixels over alpha.
    distance=np.minimum((u-left)/math.hypot(1,l1-l0),(right-u)/math.hypot(1,r1-r0))*CONTENT
    seam=np.clip(1-distance/1.4,0,1)*.10
    rgb=np.rint(rgb*(1-seam[:,:,None])).astype('uint8')
    # Edge extrusion isolates UV islands from neighbouring tiles at mip levels.
    # RGB also exists behind alpha=0, avoiding dark filtered fringes.
    pixels=np.pad(np.dstack([rgb,ar]),((GUTTER,GUTTER),(GUTTER,GUTTER),(0,0)),mode='edge')
    x=(n%8)*TILE;y=(n//8)*TILE;ATLAS.paste(Image.fromarray(pixels),(x,y))
    uv=[v*16/ATLAS_SIZE for v in [x+GUTTER,y+GUTTER,x+TILE-GUTTER,y+TILE-GUTTER]];tiles[key]=uv
    return uv

def strip(a,b,c,d,phi,color,name,hem=False,fold=False):
    """Planar trapezoid, straight horizontal cross sections, any slope.
    a/b inner (or top), d/c outer (or bottom), all coordinates local to group.
    A single positive-area rectangle with alpha polygon, opposite face mirrored.
    """
    a,b,c,d=map(lambda x:np.array(x,dtype=float),(a,b,c,d))
    dz=d[2]-a[2];dy=d[1]-a[1]
    angle=math.degrees(math.atan2(-dy,dz)); length=math.hypot(dz,dy)
    if angle<0: angle+=360
    # Our strips proceed outward/down, so 0..180 is sufficient.
    assert 0<=angle<=180,(name,angle)
    xs=[a[0],b[0],c[0],d[0]];lo=min(xs);hi=max(xs)
    poly=np.array([[(xs[i]-lo)/(hi-lo),0 if i<2 else 1] for i in range(4)])
    uv=tile(poly,color,False,hem,fold)
    under=tile(poly,tuple(int(v*.94) for v in color),True,hem,fold)
    origin=np.array([lo,a[1],a[2]])
    if angle<=45:
        f=origin; t=origin+[hi-lo,0,length];axisangle=angle;front='up';back='down'
        # Up face runs inner to outer in V. Down face runs outer to inner.
        buv=[under[0],under[3],under[2],under[1]]
    elif angle<=135:
        f=origin+[0,-length,0];t=origin+[hi-lo,0,0];axisangle=angle-90;front='south';back='north'
        buv=[under[2],under[1],under[0],under[3]]
    else:
        f=origin+[0,0,-length];t=origin+[hi-lo,0,0];axisangle=angle-180;front='down';back='up'
        uv=[uv[0],uv[3],uv[2],uv[1]];buv=under
    e={'name':name,'from':rnd(f),'to':rnd(t),'shade':False,
       'rotation':{'axis':'x','angle':round(axisangle,6),'origin':rnd(origin)},
       'faces':{front:{'uv':uv,'texture':'#0'},back:{'uv':buv,'texture':'#0'}}}
    return e

def box(f,t,color='silver',name='hardware',angle=0,origin=None):
    # Reuse original material palette for continuous shaft/grip appearance.
    idx={'silver':2,'chrome':3,'grip':4,'strap':5}[color]
    u=(idx*4+1)*.5;v=.5
    e={'name':name,'from':rnd(f),'to':rnd(t),'faces':{s:{'uv':[u,v,u+1,v+1],'texture':'#1'} for s in ['up','down','north','south','east','west']}}
    if angle:e['rotation']={'axis':'x','angle':round(angle,6),'origin':rnd(origin)}
    return e
def bar(y0,r0,y1,r1,width,name,color='silver'):
    dy=y1-y0;dr=r1-r0;L=math.hypot(dy,dr);a=math.degrees(math.atan2(-dy,dr));o=[8,y0,8+r0]
    if a<=45:return box([8-width/2,y0-width/2,8+r0],[8+width/2,y0+width/2,8+r0+L],color,name,a,o)
    return box([8-width/2,y0-L,8+r0-width/2],[8+width/2,y0,8+r0+width/2],color,name,a-90,o)

def texture_keys(e):
    e=copy.deepcopy(e)
    for f in e['faces'].values():f['texture']='#1'
    return e

def build():
    angles=[22.5+45*k for k in range(8)]
    radii=[.5,3.2,6.4,9.5,12.3,14.7,16.5]
    ys=[21-11.5*(r/16.5)**1.85 for r in radii]
    co=math.cos(math.pi/8);si=math.sin(math.pi/8)
    groups=[]
    for k,p in enumerate(angles):
        els=[];color=(126,201,232) if k%2==0 else (141,211,238)
        for j in range(len(radii)-1):
            r0,r1=radii[j:j+2];y0,y1=ys[j:j+2];w0=r0*si;w1=r1*si
            els.append(strip([8-w0,y0,8+r0*co],[8+w0,y0,8+r0*co],[8+w1,y1,8+r1*co],[8-w1,y1,8+r1*co],p,color,f'gore_{k+1}_curve_{j+1}',hem=j==5))
        groups.append((f'cloth_{k}',p,els))
    for k,p in enumerate(range(0,360,45)):
        els=[]
        for j in range(6):els.append(bar(ys[j]-.13,radii[j],ys[j+1]-.13,radii[j+1],.12,f'rib_{k}_{j}'))
        els.append(bar(13.0,.5,float(np.interp(8.8,radii,ys))-.13,8.8,.12,f'stretcher_{k}'))
        # Small metallic tip just past cloth edge.
        els.append(box([7.84,9.11,24.31],[8.16,9.51,24.88],'chrome','rib_tip'))
        groups.append((f'ribs_{k}',p,els))
    top=[box([7.48,20.84,7.48],[8.52,21.30,8.52],'chrome','crown')]
    groups.append(('crown',0,top))
    hardware=[texture_keys(e) for e in read('umbrella_stick')['elements']]
    # Shaft already lives in world coordinates, all other parts centered at 8.
    open_groups=groups+[('shaft',0,hardware)]
    closed=[]
    yr=[22.75,18,9.5,-3.8,-6]
    rr=[.23,.63,1.0,.93,.56]
    for k in range(16):
        # Alternating radii make real inward/outward pleats, not a smooth tube.
        a=2*math.pi*k/16;b=2*math.pi*(k+1)/16
        A=np.array([math.sin(a)*(2.48 if k%2==0 else 1.88),math.cos(a)*(2.48 if k%2==0 else 1.88)])
        B=np.array([math.sin(b)*(2.48 if (k+1)%2==0 else 1.88),math.cos(b)*(2.48 if (k+1)%2==0 else 1.88)])
        U=(B-A)/np.linalg.norm(B-A)
        # +X of group follows B-A. Yaw can rotate both ring endpoints to equal Z.
        p=math.degrees(math.atan2(-U[1],U[0]));q=rot('y',-p)
        va=q@np.array([A[0],0,A[1]]);vb=q@np.array([B[0],0,B[1]])
        els=[]
        for j in range(4):
            r0,r1=rr[j:j+2];y0,y1=yr[j:j+2]
            aa=[8+va[0]*r0,y0,8+va[2]*r0];bb=[8+vb[0]*r0,y0,8+vb[2]*r0]
            cc=[8+vb[0]*r1,y1,8+vb[2]*r1];dd=[8+va[0]*r1,y1,8+va[2]*r1]
            color=(130,202,232) if k%2==0 else (105,181,217)
            els.append(strip(aa,bb,cc,dd,p,color,f'fold_{k}_{j}',hem=j==3,fold=True))
        closed.append((f'fold_{k}',p,els))
    # Belt follows octagonal perimeter and narrows the cloth bundle.
    for k,p in enumerate(angles):
        belt=box([6.99,8.0,10.32],[9.01,8.9,10.49],'strap','closure_band')
        closed.append((f'band_{k}',p,[belt]))
    closedhardware=[texture_keys(e) for e in read('umbrella_closed')['elements'][-5:]]
    closedhardware += [box([5.55,8.20,10.93],[6.45,8.73,11.20],'chrome','closure_snap')]
    closed.append(('shaft',0,closedhardware))
    return {'umbrella_open':open_groups,'umbrella_closed':closed,'umbrella_canopy':groups}

def quad_faces(e):
    x,y,z=e['from'];X,Y,Z=e['to']
    quads={'north':[[X,Y,z],[x,Y,z],[x,y,z],[X,y,z]],'south':[[x,Y,Z],[X,Y,Z],[X,y,Z],[x,y,Z]],'east':[[X,Y,Z],[X,Y,z],[X,y,z],[X,y,Z]],'west':[[x,Y,z],[x,Y,Z],[x,y,Z],[x,y,z]],'up':[[x,Y,z],[X,Y,z],[X,Y,Z],[x,Y,Z]],'down':[[x,y,Z],[X,y,Z],[X,y,z],[x,y,z]]}
    for side,f in e['faces'].items():
        v=np.array(quads[side]);r=e.get('rotation')
        if r:v=(v-r['origin'])@rot(r['axis'],r['angle']).T+r['origin']
        # Our review corners use reversed winding relative to Minecraft's
        # FaceInfo. Therefore UV quadrant rotation has the opposite roll sign.
        u0,v0,u1,v1=f['uv'];uv=np.roll([[u0,v0],[u1,v0],[u1,v1],[u0,v1]],f.get('rotation',0)//90,axis=0).tolist()
        yield side,v,uv,f['texture']

def bake_y(e,degrees):
    """Bake 90-degree geometry turns including normals and UV orientation.
    Remaining element rotations stay single-axis within [-45,45].
    """
    q=rot('y',degrees);e=copy.deepcopy(e);old=copy.deepcopy(e)
    a=q@(np.array(e['from'])-8)+8;b=q@(np.array(e['to'])-8)+8
    e['from']=rnd(np.minimum(a,b));e['to']=rnd(np.maximum(a,b))
    if 'rotation' in e:
        r=e['rotation'];v=q@np.eye(3)['xyz'.index(r['axis'])];axis=int(np.argmax(abs(v)))
        r['axis']='xyz'[axis];r['angle']=round(r['angle']*v[axis],6);r['origin']=rnd(q@(np.array(r['origin'])-8)+8)
    old.pop('rotation',None);blank=copy.deepcopy(e);blank.pop('rotation',None)
    blank['faces']={s:{'texture':'#0','uv':[0,0,16,16]} for s in ['north','south','east','west','up','down']}
    targets={s:p for s,p,uv,t in quad_faces(blank)}
    normals={'north':[0,0,-1],'south':[0,0,1],'east':[1,0,0],'west':[-1,0,0],'up':[0,1,0],'down':[0,-1,0]}
    e['faces']={}
    for side,p,uv,tex in quad_faces(old):
        points=(p-8)@q.T+8;n=q@normals[side]
        side2=min(normals,key=lambda s:np.linalg.norm(n-normals[s]));target=targets[side2]
        inds=[int(np.argmin(np.linalg.norm(points-x,axis=1))) for x in target]
        desired=np.array(uv)[inds];old_uv=old['faces'][side]['uv'];found=None
        for fu in [False,True]:
            for fv in [False,True]:
                u,v,U,V=old_uv
                if fu:u,U=U,u
                if fv:v,V=V,v
                corners=np.array([[u,v],[U,v],[U,V],[u,V]])
                for turns in range(4):
                    if np.allclose(np.roll(corners,turns,axis=0),desired):
                        found={'uv':[u,v,U,V],'texture':tex}
                        if turns:found['rotation']=turns*90
                        break
                if found:break
            if found:break
        assert found is not None,(side,side2,uv,desired)
        e['faces'][side2]=found
    return e

def compact(groups):
    buckets={}
    for label,phi,els in groups:
        if label=='shaft':
            els=copy.deepcopy(els)
            for e in els:
                for k in ['from','to']:e[k]=rnd(np.array(e[k])-CENTER+8)
                if 'rotation' in e:e['rotation']['origin']=rnd(np.array(e['rotation']['origin'])-CENTER+8)
        quarter=math.floor((phi+45)/90)*90;rest=round(phi-quarter,6)
        buckets.setdefault(rest,[]).extend(bake_y(e,quarter) for e in els)
    return [(f'assembly_{i}',p,els) for i,(p,els) in enumerate(sorted(buckets.items()))]

def main():
    assets={name:compact(groups) for name,groups in build().items()};manifest={};renderdata={}; bbdata={}
    for name,groups in assets.items():
        base=display_base(name);parts=[];allfaces=[];elements=[];tree=[]
        for label,phi,els in groups:
            center=np.array([8.,8.,8.]) if label=='shaft' else CENTER.copy()
            if name=='umbrella_canopy':center+=CANOPY_SHIFT
            model={'credit':'Raingirl smooth canopy / Minecraft 1.21.8 composite','ambientocclusion':False,'textures':{'0':TEX,'1':OLDTEX,'particle':OLDTEX},'elements':els,'display':displays(base,phi,center)}
            partname=f'parts/{name}_{label}'
            dump(OUT/'models'/f'{partname}.json',model)
            parts.append({'type':'minecraft:model','model':PREFIX+partname})
            q=rot('y',phi);children=[]
            for e in els:
                vertices={};faces={};uid=str(uuid.uuid4());index=0
                for side,v,uv,tex in quad_faces(e):
                    points=(v-8)@q.T+center
                    allfaces.append({'points':np.round(points,6).tolist(),'uv':uv,'texture':tex})
                    ids=[]
                    for point in points:
                        key=f'v{index}';index+=1;vertices[key]=rnd(point);ids.append(key)
                    texture=0 if tex=='#0' else 1;sz=ATLAS_SIZE if texture==0 else 32
                    faces[side]={'vertices':list(reversed(ids)),'uv':{key:rnd(np.array(val)*sz/16) for key,val in zip(ids,uv)},'texture':texture}
                elements.append({'name':e.get('name',label),'type':'mesh','origin':[0,0,0],'rotation':[0,0,0],'vertices':vertices,'faces':faces,'uuid':uid,'visibility':True,'export':True,'color':0})
                children.append(uid)
            tree.append({'name':label,'origin':[6,8,8.5],'uuid':str(uuid.uuid4()),'children':children,'export':True,'visibility':True,'isOpen':False})
        dump(OUT/'items'/f'{name}.json',{'oversized_in_gui':True,'model':{'type':'minecraft:composite','models':parts}})
        renderdata[name]={'faces':allfaces,'display':base}
        bbdata[name]={'meta':{'format_version':'5.0','model_format':'free','box_uv':False},'name':name+'_smooth','resolution':{'width':ATLAS_SIZE,'height':ATLAS_SIZE},'elements':elements,'outliner':tree,'display':base}
        manifest[name]={'elements':sum(len(e) for _,_,e in groups),'composite_parts':len(parts),'faces':len(allfaces)}
    ATLAS.save(OUT/'umbrella_smooth.png')
    for name,data in bbdata.items():
        data['textures']=[]
        for i,path in enumerate([OUT/'umbrella_smooth.png',BACK/'umbrella.png']):
            im=Image.open(path);data['textures'].append({'name':path.name,'id':str(i),'uuid':str(uuid.uuid4()),'source':'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode(),'mode':'bitmap','width':im.width,'height':im.height,'uv_width':im.width,'uv_height':im.height,'render_mode':'default'})
        dump(OUT/f'{name}.bbmodel',data)
    dump(OUT/'renderdata.json',renderdata);dump(OUT/'manifest.json',manifest)
    dump(OUT/'texture_layout.json',{'size':ATLAS_SIZE,'tile':TILE,'gutter':GUTTER,'content':CONTENT,'supersampling':AA,'islands':[{'parameters':json.loads(k),'uv':v} for k,v in tiles.items()]})
    stick=read('umbrella_stick');stick['display']=display_base('umbrella_stick')
    dump(OUT/'models/umbrella_stick.json',stick)
    stick_bb=json.loads((Path(__file__).parent/'umbrella_stick.bbmodel').read_text(encoding='utf-8'))
    stick_bb['display']=stick['display'];dump(OUT/'umbrella_stick.bbmodel',stick_bb)
    print(json.dumps(manifest,indent=2))

if __name__=='__main__':main()
